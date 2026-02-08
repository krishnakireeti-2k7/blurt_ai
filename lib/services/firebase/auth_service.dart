import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  static Future<User?> signInAnonymouslyIfNeeded() async {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('👤 Existing user: ${user.uid} (anon=${user.isAnonymous})');
      return user;
    }

    final cred = await _auth.signInAnonymously();
    debugPrint('👤 Anonymous signed in: ${cred.user?.uid}');
    return cred.user;
  }

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
      debugPrint('🔗 Linked anon → Google: ${result.user?.uid}');
      return result.user;
    }

    final result = await _auth.signInWithCredential(credential);
    debugPrint('👤 Google signed in: ${result.user?.uid}');
    return result.user;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
