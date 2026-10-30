import 'package:cloud_functions/cloud_functions.dart';
import 'auth_identity.dart';
import 'profile_selection.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import 'main_wrapper.dart';
import 'forgot_password_screen.dart';
import 'responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? emailError;
  String? passwordError;
  String? generalError;
  String? childCodeError;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _activeForm = 'choice';
  final _familyCodeController = TextEditingController();
  String? _hoveredRole;
  String? _pressedRole;

  static const Color primary = Color(0xFF6A5ACD);
  static const Color primaryLight = Color(0xFFF3EEFF);
  static const Color textDark = Color(0xFF2D3142);
  static const Color softBlue = Color(0xFFEFF7FF);
  static const Color softPink = Color(0xFFFFF5F8);
  static const Color softCard = Colors.white;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    bool isValid = true;

    setState(() {
      emailError = null;
      passwordError = null;
      generalError = null;

      if (email.isEmpty) {
        emailError = 'Field required';
        isValid = false;
      }
      if (pass.isEmpty) {
        passwordError = 'Field required';
        isValid = false;
      }
    });

    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'sessionActive': true,
        }, SetOptions(merge: true));
      }

      AuthIdentity.clearChild();
      AuthIdentity.familyCode = null;
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'network-request-failed') {
          generalError = "Network error. Please try again";
        } else {
          generalError = "Invalid email or password";
        }
      });
    } catch (_) {
      setState(() {
        generalError = "Invalid email or password";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _input(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: GoogleFonts.montserrat(
        fontSize: R.text(11),
        color: Colors.black38,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primary, size: R.icon(17)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(18)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(18)),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.035)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(18)),
        borderSide: const BorderSide(color: primary, width: 1.15),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(18)),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(18)),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
      errorText: errorText,
      errorStyle: GoogleFonts.montserrat(
        color: Colors.red,
        fontSize: R.text(10),
        fontWeight: FontWeight.w500,
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: R.space(13),
        horizontal: R.space(12),
      ),
    );
  }

  Widget _roleButton({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final bool highlighted = _hoveredRole == role || _pressedRole == role;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRole = role),
      onExit: (_) => setState(() => _hoveredRole = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: highlighted ? primary : Colors.white,
          borderRadius: BorderRadius.circular(R.radius(18)),
          border: Border.all(
            color: highlighted ? primary : primary.withOpacity(0.45),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(R.radius(18)),
          child: InkWell(
            borderRadius: BorderRadius.circular(R.radius(18)),
            onHighlightChanged: (pressed) => setState(() {
              _pressedRole = pressed ? role : null;
            }),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: R.space(15),
                vertical: R.space(14),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    padding: EdgeInsets.all(R.space(8)),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? Colors.white.withOpacity(0.17)
                          : primaryLight,
                      borderRadius: BorderRadius.circular(R.radius(12)),
                    ),
                    child: Icon(
                      icon,
                      size: R.icon(25),
                      color: highlighted ? Colors.white : primary,
                    ),
                  ),
                  SizedBox(width: R.space(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(12.5),
                            fontWeight: FontWeight.w700,
                            color: highlighted ? Colors.white : textDark,
                          ),
                        ),
                        SizedBox(height: R.space(3)),
                        Text(
                          subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(9.5),
                            color: highlighted
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: R.icon(14),
                    color: highlighted ? Colors.white : primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _parentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Choose login type',
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                      _activeForm = 'choice';
                      generalError = null;
                    }),
              icon: const Icon(Icons.arrow_back_rounded, color: primary),
            ),
            Expanded(
              child: Text(
                'Parent Login',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(18),
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: R.space(5)),
        Text(
          'Welcome back! Log in to continue.',
          style: GoogleFonts.montserrat(
            fontSize: R.text(11),
            color: Colors.black54,
          ),
        ),
        SizedBox(height: R.space(23)),
        TextField(
          controller: _emailController,
          onChanged: (_) {
            if (emailError != null || generalError != null) {
              setState(() {
                emailError = null;
                generalError = null;
              });
            }
          },
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.montserrat(fontSize: R.text(11)),
          decoration: _input(
            'Enter your email',
            Icons.email_outlined,
            errorText: emailError,
          ),
        ),
        SizedBox(height: R.space(15)),
        TextField(
          controller: _passwordController,
          onChanged: (_) {
            if (passwordError != null || generalError != null) {
              setState(() {
                passwordError = null;
                generalError = null;
              });
            }
          },
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.montserrat(fontSize: R.text(11)),
          decoration: _input(
            'Enter your password',
            Icons.lock_outline_rounded,
            errorText: passwordError,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.black38,
                size: R.icon(17),
              ),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.montserrat(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: R.text(10.5),
              ),
            ),
          ),
        ),
        if (generalError != null)
          Padding(
            padding: EdgeInsets.only(bottom: R.space(9)),
            child: Text(
              generalError!,
              style: GoogleFonts.montserrat(
                color: Colors.red,
                fontSize: R.text(10),
              ),
            ),
          ),
        SizedBox(height: R.space(7)),
        SizedBox(
          width: double.infinity,
          height: R.buttonH(47),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              disabledBackgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.radius(18)),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    'Log In',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: R.text(12),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _childForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Choose login type',
              onPressed: () => setState(() {
                _activeForm = 'choice';
                childCodeError = null;
              }),
              icon: const Icon(Icons.arrow_back_rounded, color: primary),
            ),
            Expanded(
              child: Text(
                'Child Login',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(18),
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: R.space(5)),
        Text(
          'Ask your parent for your Family Code.',
          style: GoogleFonts.montserrat(
            fontSize: R.text(11),
            color: Colors.black54,
          ),
        ),
        SizedBox(height: R.space(23)),
        TextField(
          controller: _familyCodeController,
          onChanged: (_) {
            if (childCodeError != null) {
              setState(() => childCodeError = null);
            }
          },
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          maxLength: 19,
          style: GoogleFonts.montserrat(fontSize: R.text(11)),
          decoration: _input(
            'Enter your Family Code',
            Icons.lock_outline_rounded,
            errorText: childCodeError,
          ).copyWith(counterText: ''),
          onSubmitted: (_) => _childContinue(),
        ),
        SizedBox(height: R.space(22)),
        SizedBox(
          width: double.infinity,
          height: R.buttonH(47),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _childContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.radius(18)),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    'Continue',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: R.text(12),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _childContinue() async {
    if (_isLoading) return;
    final code = _familyCodeController.text.toUpperCase().replaceAll(
      RegExp(r'[\s-]'),
      '',
    );
    if (code.isEmpty) {
      setState(() => childCodeError = 'Field required');
      return;
    }
    if (code.length != 16) {
      setState(() => childCodeError = 'Enter your 16-character Family Code.');
      return;
    }
    setState(() {
      childCodeError = null;
      _isLoading = true;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'me-central1',
      ).httpsCallable('verifyFamilyCode');
      final result = await callable.call<Map<String, dynamic>>({
        'familyCode': code,
      });
      final profiles = (result.data['profiles'] as List<dynamic>? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      AuthIdentity.familyCode = code;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileSelectionPage(familyCode: code, profiles: profiles),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(
        () => childCodeError = e.message ?? 'Unable to verify Family Code.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => childCodeError = 'Could not connect. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [softBlue, softPink, Color(0xFFFFFCFF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              R.pagePad,
              R.space(40),
              R.pagePad,
              R.space(25),
            ),
            children: [
              Center(
                child: Image.asset(
                  'assets/Lexia.png',
                  width: R.s(160),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: R.space(37)),
              Container(
                padding: EdgeInsets.all(R.space(18)),
                decoration: BoxDecoration(
                  color: softCard.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(R.radius(28)),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.055),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  reverseDuration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final isForm = child.key != const ValueKey('role-choice');
                    // Both login forms enter from the right; options move left.
                    final enteringFrom = isForm ? 1.0 : -1.0;
                    return ClipRect(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(enteringFrom, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                  child: _activeForm == 'parent'
                      ? KeyedSubtree(
                          key: const ValueKey('parent-form'),
                          child: _parentForm(),
                        )
                      : _activeForm == 'child'
                      ? KeyedSubtree(
                          key: const ValueKey('child-form'),
                          child: _childForm(),
                        )
                      : Column(
                          key: const ValueKey('role-choice'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: R.space(8)),
                            Text(
                              'Welcome to Lexia!',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(18),
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: R.space(8)),
                            Text(
                              'Choose how you would like to continue.',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(11),
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: R.space(25)),
                            _roleButton(
                              title: 'Log In as Parent',
                              subtitle: 'Email and password',
                              icon: Icons.family_restroom_rounded,
                              role: 'parent',
                              onPressed: () =>
                                  setState(() => _activeForm = 'parent'),
                            ),
                            SizedBox(height: R.space(13)),
                            _roleButton(
                              title: 'Log In as Child',
                              subtitle: 'Use your Family Code',
                              icon: Icons.child_care_rounded,
                              role: 'child',
                              onPressed: () =>
                                  setState(() => _activeForm = 'child'),
                            ),
                            SizedBox(height: R.space(8)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: R.space(20)),
              if (_activeForm != 'child')
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Don’t have an account? ',
                        style: GoogleFonts.montserrat(
                          fontSize: R.text(10.5),
                          color: Colors.black54,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(10.5),
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
