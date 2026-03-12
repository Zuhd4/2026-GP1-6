import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_wrapper.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // For Sprint 1: We set this to 'false' so it always shows the Login Screen.
    // In Sprint 2: This will be: final user = Provider.of<User?>(context);
    bool isLoggedIn = false; 

    if (isLoggedIn) {
      return const MainWrapper();
    } else {
      return const LoginScreen();
    }
  }
}