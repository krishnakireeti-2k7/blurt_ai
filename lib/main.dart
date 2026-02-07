import 'package:flutter/material.dart';
import 'package:blurt_ai/app/app.dart';
import 'package:blurt_ai/services/firebase/firebase_init.dart';
import 'package:blurt_ai/services/firebase/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInit.init();

  // 🔒 Silent anon auth
  await AuthService.signInAnonymouslyIfNeeded();

  runApp(const App());
}
