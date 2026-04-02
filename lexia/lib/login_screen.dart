import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import 'profile_selection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color skyBlue = Color(0xFFD4EFFF);

  // --- LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty)
      return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
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
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
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
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.60,
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
                  SizedBox(height: 12.h),
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.montserrat(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 25.h),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45.w),
                    child: Column(
                      children: [
                        _buildField(
                          "Email",
                          "parent@example.com",
                          _emailController,
                        ),
                        SizedBox(height: 12.h),
                        _buildField(
                          "Password",
                          "........",
                          _passwordController,
                          isObscure: true,
                        ),
                        SizedBox(height: 30.h),
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
                            onPressed: _isLoading ? null : _handleLogin,
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
                                    "Sign In",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          child: Text(
                            "New here? Create Account",
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

          Expanded(
            child: Stack(
              children: [
                Transform.translate(
                  offset: Offset(-40.w, -100.h),
                  child: Container(
                    alignment: Alignment.bottomLeft,
                    child: Image.asset(
                      'assets/charchter2.png',
                      width: 300.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 45.w, bottom: 150.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "We missed",
                        style: GoogleFonts.montserrat(
                          fontSize: 25.sp,
                          fontWeight: FontWeight.w600,
                          color: textDark.withOpacity(0.9),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        "you!",
                        style: GoogleFonts.montserrat(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w500,
                          color: textDark.withOpacity(0.8),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isObscure = false,
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
        SizedBox(height: 5.h),
        SizedBox(
          height: 36.h,
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: TextStyle(fontSize: 11.sp),
            decoration: InputDecoration(
              hintText: hint,
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
