import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_page.dart';
import 'main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showFullLogo = false;

  @override
  void initState() {
    super.initState();
    _playSequence();
  }

  void _playSequence() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _showFullLogo = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final User? user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              user == null ? const OnboardingPage() : const MainWrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAE7),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Image.asset(
            _showFullLogo ? 'assets/icon.png' : 'assets/e_happy.png',
            key: ValueKey(_showFullLogo),
            width: _showFullLogo ? sw * 0.62 : sw * 0.44,
          ),
        ),
      ),
    );
  }
}
