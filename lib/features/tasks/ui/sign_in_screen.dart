import 'package:flutter/material.dart';
import 'package:blurt_ai/services/firebase/auth_service.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user = await AuthService.signInWithGoogleAndLink();
            if (user != null && context.mounted) {
              // Replace with your post-login placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed in with Google')),
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
