import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'profile_selection.dart';

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

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color skyBlue = Color(0xFFD4EFFF);

  // --- REGISTRATION LOGIC ---
  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty)
      return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: skyBlue,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. WHITE CARD (82% to fit all fields)
            Container(
              height: screenHeight * 0.82,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    Image.asset('assets/Lexia.png', width: 170.w),
                    SizedBox(height: 15.h),
                    Text(
                      "Create Account",
                      style: GoogleFonts.montserrat(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 15.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 45.w),
                      child: Column(
                        children: [
                          _buildField("Name", "John Doe", _nameController),
                          SizedBox(height: 6.h),
                          _buildField(
                            "Email",
                            "parent@example.com",
                            _emailController,
                          ),
                          SizedBox(height: 6.h),
                          _buildField(
                            "Password",
                            "........",
                            _passwordController,
                            isObscure: true,
                          ),
                          SizedBox(height: 6.h),
                          _buildField(
                            "Confirm Password",
                            "........",
                            _confirmPasswordController,
                            isObscure: true,
                          ),
                          SizedBox(height: 6.h),
                          _buildField(
                            "Parental PIN",
                            "4 Digits",
                            _pinController,
                            isObscure: true,
                            isPin: true,
                          ),

                          SizedBox(height: 25.h),

                          SizedBox(
                            width: double.infinity,
                            height: 40.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPurple,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleSignUp,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 18.h,
                                      width: 18.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Get Started",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            child: Text(
                              "Already registered? Log In",
                              style: GoogleFonts.montserrat(
                                fontSize: 8.5.sp,
                                color: Colors.black45,
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

            // 2. BLUE BOTTOM SECTION
            Container(
              height: screenHeight * 0.18,
              width: double.infinity,
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(40.w, -60.h),
                    child: Container(
                      alignment: Alignment.bottomRight,
                      child: Image.asset(
                        'assets/charcter.png',
                        width: 200.w,
                        fit: BoxFit.contain,
                        opacity: const AlwaysStoppedAnimation(0.9),
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 45.w, bottom: 50.h),
                    child: Text(
                      "Welcome\nto Lexia!",
                      style: GoogleFonts.montserrat(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: textDark.withOpacity(0.8),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isObscure = false,
    bool isPin = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 8.5.sp,
            color: textDark.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        SizedBox(
          height: 36.h,
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            keyboardType: isPin ? TextInputType.number : TextInputType.text,
            maxLength: isPin ? 4 : null,
            style: TextStyle(fontSize: 11.sp),
            decoration: InputDecoration(
              hintText: hint,
              counterText: "",
              hintStyle: TextStyle(fontSize: 10.sp, color: Colors.black12),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
