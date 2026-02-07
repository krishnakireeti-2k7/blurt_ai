import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // ✅ Create ONE instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  /// 1️⃣ Silent anonymous sign-in
  static Future<User?> signInAnonymouslyIfNeeded() async {
    final current = _auth.currentUser;
    if (current != null) {
      debugPrint(
        '👤 Existing user: ${current.uid} (anon=${current.isAnonymous})',
      );
      return current;
    }

    final cred = await _auth.signInAnonymously();
    debugPrint('👤 Anonymous signed in: ${cred.user?.uid}');
    return cred.user;
  }

  /// 2️⃣ Google Sign-In + LINK
  static Future<User?> signInWithGoogleAndLink() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = _auth.currentUser;

    if (user != null && user.isAnonymous) {
      final result = await user.linkWithCredential(credential);
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
