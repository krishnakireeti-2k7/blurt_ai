import 'package:flutter/material.dart';
import 'package:blurt_ai/app/app.dart';
import 'package:blurt_ai/services/firebase/firebase_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInit.init();

  runApp(const App());
}
