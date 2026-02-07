import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInit {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase init failed: $e');
      rethrow;
    }
  }
}
