import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blurt_ai/features/tasks/ui/sign_in_screen.dart';
import 'package:blurt_ai/features/tasks/ui/task_list_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user not logged in → show sign in
          if (!snapshot.hasData) {
            return const SignInScreen();
          }

          // If logged in → show home
          return const TaskListScreen();
        },
      ),
    );
  }
}
