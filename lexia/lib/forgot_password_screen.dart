import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'responsive_helper.dart';
import 'widgets/lexia_popup.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? emailError;
  String? generalError;
  String? successMessage;

  static const Color primary = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);
  static const Color softBlue = Color(0xFFEFF7FF);
  static const Color softPink = Color(0xFFFFF5F8);
  static const Color softCard = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_isLoading) return;

    final email = _emailController.text.trim().toLowerCase();

    bool isValidEmailFormat(String email) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (!emailRegex.hasMatch(email)) {
        return false;
      }

      if (email.contains('..') ||
          email.startsWith('.') ||
          email.endsWith('.') ||
          email.contains('@.') ||
          email.contains('.@')) {
        return false;
      }

      final allowedDomains = [
        'gmail.com',
        'hotmail.com',
        'outlook.com',
        'icloud.com',
        'yahoo.com',
      ];

      final domain = email.split('@').last;
      return allowedDomains.contains(domain);
    }

    bool isValid = true;

    setState(() {
      emailError = null;
      generalError = null;
      successMessage = null;

      if (email.isEmpty) {
        emailError = "Please enter your email address";
        isValid = false;
      } else if (!isValidEmailFormat(email)) {
        emailError = "Please enter a valid email address";
        isValid = false;
      }
    });

    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        successMessage = null;
        emailError = null;
        generalError = null;
      });

      await LexiaPopup.showMessage(
        context: context,
        title: "Reset Link Sent",
        message: "Please check your email to reset your password.",
        icon: Icons.mark_email_read_outlined,
        iconColor: primary,
        buttonColor: primary,
        buttonText: "OK",
        barrierDismissible: false,
        onDone: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );

      return;
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Specific handling for unregistered accounts
        if (e.code == 'user-not-found') {
          generalError = "This email is not registered";
        } else if (e.code == 'invalid-email') {
          emailError = "Please enter a valid email address";
        } else if (e.code == 'network-request-failed') {
          generalError = "Network error. Please check your connection";
        } else {
          generalError = "Could not send reset link. Please try again";
        }
        successMessage = null;
      });
    } catch (e) {
      setState(() {
        generalError = "An unexpected error occurred. Please try again";
        successMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _input(String hint, IconData icon, {String? errorText}) {
    return InputDecoration(
      labelText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: GoogleFonts.montserrat(
        fontSize: R.text(11),
        color: Colors.black38,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primary, size: R.icon(17)),
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
              SizedBox(height: R.space(40)),
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
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: R.space(10)),
                    Text(
                      "Forgot password?",
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(18),
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: R.space(6)),
                    Text(
                      "Enter your email to reset it.",
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
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.montserrat(fontSize: R.text(11)),
                      decoration: _input(
                        "Enter your email",
                        Icons.email_outlined,
                        errorText: emailError,
                      ),
                      onSubmitted: (_) => _sendResetEmail(),
                    ),

                    // Error and Success messages
                    if (generalError != null) ...[
                      SizedBox(height: R.space(10)),
                      Text(
                        generalError!,
                        style: GoogleFonts.montserrat(
                          color: Colors.red,
                          fontSize: R.text(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (successMessage != null) ...[
                      SizedBox(height: R.space(10)),
                      Text(
                        successMessage!,
                        style: GoogleFonts.montserrat(
                          color: Colors.green,
                          fontSize: R.text(10),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],

                    SizedBox(height: R.space(20)),
                    SizedBox(
                      width: double.infinity,
                      height: R.buttonH(47),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetEmail,
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
                                "Send Reset Link",
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
              SizedBox(height: R.space(24)),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    "Back to Login",
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(10.5),
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
