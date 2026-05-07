import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import 'profile_selection.dart';
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

  bool _isLoading = false;
  bool _obscurePassword = true;

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
        emailError = "Email is required";
        isValid = false;
      }

      if (pass.isEmpty) {
        passwordError = "Password is required";
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

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSelectionPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-email':
            emailError = "Invalid email";
            break;
          case 'user-not-found':
            emailError = "No account found";
            break;
          case 'wrong-password':
            passwordError = "Incorrect password";
            break;
          case 'invalid-credential':
            generalError = "Invalid email or password";
            break;
          case 'network-request-failed':
            generalError = "Network error. Please try again";
            break;
          default:
            generalError = "Login failed";
        }
      });
    } catch (_) {
      setState(() {
        generalError = "Login failed";
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              R.space(34),
              R.pagePad,
              R.space(16) + bottomInset,
            ),
            children: [
              Center(
                child: Image.asset(
                  "assets/Lexia.png",
                  width: R.s(138),
                  fit: BoxFit.contain,
                ),
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
                    SizedBox(height: R.space(10)),
                    Text(
                      "Welcome back",
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(18),
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: R.space(6)),
                    Text(
                      "Log in to continue!",
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(11),
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: R.space(25)),

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
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.montserrat(fontSize: R.text(11)),
                      decoration: _input(
                        "Enter your password",
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
                      onSubmitted: (_) => _login(),
                    ),
                    SizedBox(height: R.space(6)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: R.space(6),
                            vertical: R.space(4),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(10.3),
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                    if (generalError != null) ...[
                      SizedBox(height: R.space(4)),
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
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
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
                                "Log In",
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
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "Don’t have an account? ",
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(10.5),
                        color: Colors.black54,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                      child: Text(
                        "Sign Up",
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
