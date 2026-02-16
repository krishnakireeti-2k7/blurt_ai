import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Ensure user document exists
  static Future<void> _createUserDocumentIfNotExists(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'createdAt': FieldValue.serverTimestamp(),
        'isAnonymous': user.isAnonymous,
      });
      debugPrint('📁 Created Firestore user doc for ${user.uid}');
    }
  }

  // 🔹 Anonymous sign in
  static Future<User?> signInAnonymouslyIfNeeded() async {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('👤 Existing user: ${user.uid} (anon=${user.isAnonymous})');
      return user;
    }

    final cred = await _auth.signInAnonymously();
    final newUser = cred.user;

    if (newUser != null) {
      await _createUserDocumentIfNotExists(newUser);
      debugPrint('👤 Anonymous signed in: ${newUser.uid}');
    }

    return newUser;
  }

  // 🔹 Google sign in + link if anonymous
  static Future<User?> signInWithGoogleAndLink() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final currentUser = _auth.currentUser;

    if (currentUser != null && currentUser.isAnonymous) {
      final result = await currentUser.linkWithCredential(credential);
      final linkedUser = result.user;

      if (linkedUser != null) {
        await _createUserDocumentIfNotExists(linkedUser);
        debugPrint('🔗 Linked anon → Google: ${linkedUser.uid}');
      }

      return linkedUser;
    }

    final result = await _auth.signInWithCredential(credential);
    final signedInUser = result.user;

    if (signedInUser != null) {
      await _createUserDocumentIfNotExists(signedInUser);
      debugPrint('👤 Google signed in: ${signedInUser.uid}');
    }

    return signedInUser;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
