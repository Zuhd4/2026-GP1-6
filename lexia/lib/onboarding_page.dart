import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const Color primaryPurple = Color(0xFF6A5ACD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F1FF), Colors.white, Color(0xFFF9F7F8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 45.w,
                ), // Increased padding for a slimmer look
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. LOGO
                    Image.asset(
                      'assets/Lexia.png',
                      width:
                          220.w, // Slightly smaller logo to match smaller fonts
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: 50.h),

                    // 2. MAIN TITLE (Smaller & Black)
                    Text(
                      "Interactive Learning",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12.sp, // Scaled down from 22
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // 3. SUBTITLE (Smaller & Gray)
                    Text(
                      "Learning made simple and fun,\nespecially for your child",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 8.sp, // Scaled down from 13
                        fontWeight: FontWeight.w400,
                        color: Colors.black45,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 35.h),

                    // 4. BUTTONS
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 46.h, // Slightly skinnier buttons
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            ),
                            child: Text(
                              "Get Started",
                              style: GoogleFonts.montserrat(
                                fontSize: 8.5.sp, // Scaled down from 12
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.6),
                              side: BorderSide(
                                color: primaryPurple.withOpacity(0.1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            ),
                            child: Text(
                              "I already have an account",
                              style: GoogleFonts.montserrat(
                                fontSize: 8.sp, // Scaled down from 11
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
