import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_wrapper.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to Firebase and rebuilds whenever the user changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If snapshot has data, a user is logged in
        if (snapshot.hasData) {
          return const MainWrapper();
        } else {
          // Otherwise, show Login
          return const LoginScreen();
        }
      },
    );
  }
}
