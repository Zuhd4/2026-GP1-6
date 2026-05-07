import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'profile_selection.dart';
import 'responsive_helper.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? pinError;
  String? generalError;

  static const Color primary = Color(0xFF6A5ACD);
  static const Color primaryLight = Color(0xFFF3EEFF);
  static const Color textDark = Color(0xFF2D3142);
  static const Color softBlue = Color(0xFFEFF7FF);
  static const Color softPink = Color(0xFFFFF5F8);
  static const Color softCard = Colors.white;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    bool isValid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final pin = _pinController.text.trim();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    setState(() {
      generalError = null;

      nameError = _nameController.text.trim().isEmpty
          ? "Name is required"
          : _nameController.text.trim().length > 12
          ? "Max 12 characters allowed"
          : null;

      if (email.isEmpty) {
        emailError = "Email is required";
      } else if (!emailRegex.hasMatch(email)) {
        emailError = "Invalid email";
      } else {
        emailError = null;
      }

      if (password.isEmpty) {
        passwordError = "Password is required";
      } else if (password.length < 8) {
        passwordError = "Min. 8 characters";
      } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
        passwordError = "Must contain 1 uppercase letter";
      } else if (!RegExp(r'[a-z]').hasMatch(password)) {
        passwordError = "Must contain 1 lowercase letter";
      } else if (!RegExp(r'[0-9]').hasMatch(password)) {
        passwordError = "Must contain 1 number";
      } else {
        passwordError = null;
      }

      if (confirmPassword.isEmpty) {
        confirmPasswordError = "Please confirm password";
      } else if (confirmPassword != password) {
        confirmPasswordError = "Passwords do not match";
      } else {
        confirmPasswordError = null;
      }

      if (pin.isEmpty) {
        pinError = "4-digit PIN required";
      } else if (!RegExp(r'^\d+$').hasMatch(pin)) {
        pinError = "PIN must contain numbers only";
      } else if (pin.length != 4) {
        pinError = "PIN must be exactly 4 digits";
      } else {
        pinError = null;
      }

      if (nameError != null ||
          emailError != null ||
          passwordError != null ||
          confirmPasswordError != null ||
          pinError != null) {
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
      generalError = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'uid': cred.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'pin': _pinController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSelectionPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            generalError = "This email is already in use";
            break;
          case 'invalid-email':
            generalError = "Invalid email address";
            break;
          case 'weak-password':
            generalError = "Password is too weak";
            break;
          case 'network-request-failed':
            generalError = "Network error. Please try again";
            break;
          default:
            generalError = e.message ?? "Registration failed";
        }
      });
    } on FirebaseException catch (e) {
      setState(() {
        generalError = e.message ?? "Could not save account data";
      });
    } catch (_) {
      setState(() {
        generalError = "Something went wrong. Please try again";
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

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [softPink, softBlue, Color(0xFFFFFCFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: R.pagePad),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: R.space(34)),

                  Image.asset(
                    "assets/Lexia.png",
                    width: R.s(138),
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: R.space(16)),

                  SizedBox(height: R.space(24)),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(R.space(18)),
                    decoration: BoxDecoration(
                      color: softCard.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(R.radius(28)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A5ACD).withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.035),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: R.space(10),
                        ), // 👈 add this (top padding)

                        Text(
                          "Welcome to Lexia",
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(18),
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: R.space(6)),
                        Text(
                          "Let’s create your account!",
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(11),
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: R.space(25)),

                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          maxLength: 12,
                          style: GoogleFonts.montserrat(fontSize: R.text(11)),
                          decoration: _input(
                            "Enter your name",
                            Icons.person_outline_rounded,
                            errorText: nameError,
                          ).copyWith(counterText: ""),
                        ),

                        SizedBox(height: R.space(13)),

                        SizedBox(height: R.space(7)),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.montserrat(fontSize: R.text(11)),
                          decoration: _input(
                            "Enter your email",
                            Icons.email_outlined,
                            errorText: emailError,
                          ),
                        ),

                        SizedBox(height: R.space(13)),

                        SizedBox(height: R.space(7)),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.montserrat(fontSize: R.text(11)),
                          decoration: _input(
                            "Create a password",
                            Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: R.icon(17),
                                color: Colors.black38,
                              ),
                            ),
                            errorText: passwordError,
                          ),
                        ),

                        SizedBox(height: R.space(13)),

                        SizedBox(height: R.space(7)),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.montserrat(fontSize: R.text(11)),
                          decoration: _input(
                            "Re-enter your password",
                            Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: R.icon(17),
                                color: Colors.black38,
                              ),
                            ),
                            errorText: confirmPasswordError,
                          ),
                        ),

                        SizedBox(height: R.space(13)),

                        SizedBox(height: R.space(7)),
                        TextField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: GoogleFonts.montserrat(fontSize: R.text(11)),
                          decoration: _input(
                            "Create a 4-digit PIN",
                            Icons.pin_outlined,
                            errorText: pinError,
                          ),
                          onSubmitted: (_) => _handleSignUp(),
                        ),

                        if (generalError != null) ...[
                          SizedBox(height: R.space(8)),
                          Text(
                            generalError!,
                            style: GoogleFonts.montserrat(
                              color: Colors.red,
                              fontSize: R.text(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        SizedBox(height: R.space(14)),

                        SizedBox(
                          width: double.infinity,
                          height: R.buttonH(47),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  R.radius(18),
                                ),
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
                                    "Create Account",
                                    style: GoogleFonts.montserrat(
                                      fontSize: R.text(12),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.space(18)),

                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.montserrat(
                          fontSize: R.text(10.5),
                          color: Colors.black54,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: Text(
                          "Log In",
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(10.5),
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: R.space(16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
