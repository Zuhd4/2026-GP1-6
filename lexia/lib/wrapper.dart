import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lexia/profile_selection.dart';
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
        if (snapshot.hasData) {
          // Changed from MainWrapper to ProfileSelectionPage
          return const ProfileSelectionPage();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
