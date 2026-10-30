import 'auth_identity.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onboarding_page.dart';
import 'main_wrapper.dart';
import 'profile_selection.dart';

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

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _showFullLogo = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final destination = await _resolveDestination();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<Widget> _resolveDestination() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // A previously selected family survives the child's Firebase sign-out.
      // The app must reopen on the picker, not on the onboarding/login flow.
      return _rememberedFamilyPicker();
    }

    try {
      final result = await user
          .getIdTokenResult(true)
          .timeout(const Duration(seconds: 12));

      final claims = result.claims ?? {};
      await AuthIdentity.refresh();
      final role = claims['role'];
      final provider = result.signInProvider;

      debugPrint('LEXIA AUTH - Provider: $provider');
      debugPrint('LEXIA AUTH - Role: $role');

      if (role == 'child') {
        // On a fresh launch, never restore the child's old authenticated page.
        await FirebaseAuth.instance.signOut();
        AuthIdentity.clearChild();
        return _rememberedFamilyPicker();
      }

      if (provider == 'password' && role != 'child') {
        return const MainWrapper(isChildMode: false);
      }

      return const OnboardingPage();
    } catch (e) {
      debugPrint('LEXIA AUTH - Startup error: $e');

      // Do not route an unverified session
      // into a parent dashboard.
      return const OnboardingPage();
    }
  }

  Future<Widget> _rememberedFamilyPicker() async {
    try {
      final code = await AuthIdentity.storedFamilyCode();
      if (code == null || code.isEmpty) return const OnboardingPage();
      final cached = await AuthIdentity.storedProfiles(code);
      final profiles = cached.isNotEmpty
          ? cached
          : await AuthIdentity.loadFamilyProfiles(code);
      return ProfileSelectionPage(familyCode: code, profiles: profiles);
    } catch (error) {
      debugPrint('LEXIA AUTH - Could not restore family picker: $error');
      return const OnboardingPage();
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
