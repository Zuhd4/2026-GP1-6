import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'onboarding_page.dart'; // Import the new new file
import 'profile_selection.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While Firebase checks the auth state, show a generic loading page.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Case 1: The user is authenticated -> Go to Profile Selection
          if (snapshot.hasData && snapshot.data != null) {
            return const ProfileSelectionPage();
          }
          // Case 2: No user is logged in -> SHOW THE ONBOARDING PAGE FIRST
          else {
            return const OnboardingPage();
          }
        },
      ),
    );
  }
}
