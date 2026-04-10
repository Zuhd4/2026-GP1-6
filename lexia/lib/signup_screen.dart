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

  String? nameError;
  String? emailError;
  String? emailExistsError;
  String? passwordError;
  String? confirmPasswordError;
  String? pinError;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color skyBlue = Color(0xFFD4EFFF);

  // ================= VALIDATION =================
  bool _validateFields() {
    final password = _passwordController.text;
    bool isValid = true;

    setState(() {
      nameError = _nameController.text.isEmpty ? "Name is required" : null;
      if (nameError != null) isValid = false;

      emailError = _emailController.text.isEmpty
          ? "Email is required"
          : (!_emailController.text.contains("@") ? "Invalid email" : null);
      if (emailError != null) isValid = false;

      if (password.isEmpty) {
        passwordError = "Password is required";
      } else if (password.length < 8) {
        passwordError = "At least 8 characters";
      } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
        passwordError = "Must include uppercase letter";
      } else if (!RegExp(r'[a-z]').hasMatch(password)) {
        passwordError = "Must include lowercase letter";
      } else {
        passwordError = null;
      }
      if (passwordError != null) isValid = false;

      confirmPasswordError = _confirmPasswordController.text != password
          ? "Passwords do not match"
          : null;
      if (confirmPasswordError != null) isValid = false;

      pinError = !RegExp(r'^[0-9]{4}$').hasMatch(_pinController.text)
          ? "PIN must be 4 digits"
          : null;
      if (pinError != null) isValid = false;
    });

    return isValid;
  }

  // ================= CHECK EMAIL =================
  Future<bool> _checkEmailExistsNow() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: "Temp1234!",
      );

      await FirebaseAuth.instance.currentUser?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true;
      }
      return false;
    }
  }

  // ================= SIGN UP =================
  Future<void> _handleSignUp() async {
    final isValid = _validateFields();

    // 🔥 تحقق الإيميل هنا مع باقي الأخطاء
    bool emailExists = false;

    if (_emailController.text.isNotEmpty &&
        _emailController.text.contains("@")) {
      emailExists = await _checkEmailExistsNow();
    }

    setState(() {
      emailExistsError = emailExists
          ? "This email is already registered"
          : null;
    });

    if (!isValid || emailExists) return;

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
            'avatarUrl': 'assets/lexiaAv.png',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSelectionPage()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: skyBlue,
      body: SingleChildScrollView(
        // 🔥 حل overflow
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40.r),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    Image.asset('assets/Lexia.png', width: 170.w),
                    SizedBox(height: 15.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 45.w),
                      child: Column(
                        children: [
                          _buildField(
                            "Name",
                            "John Doe",
                            _nameController,
                            errorText: nameError,
                          ),

                          _buildField(
                            "Email",
                            "parent@example.com",
                            _emailController,
                            errorText: emailError ?? emailExistsError,
                          ),

                          _buildField(
                            "Password",
                            "........",
                            _passwordController,
                            isObscure: true,
                            errorText: passwordError,
                          ),

                          _buildField(
                            "Confirm Password",
                            "........",
                            _confirmPasswordController,
                            isObscure: true,
                            errorText: confirmPasswordError,
                          ),

                          _buildField(
                            "Parental PIN",
                            "4 Digits",
                            _pinController,
                            isObscure: true,
                            isPin: true,
                            errorText: pinError,
                          ),

                          SizedBox(height: 25.h),

                          SizedBox(
                            width: double.infinity,
                            height: 40.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleSignUp,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text("Get Started"),
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

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FIELD =================
  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isObscure = false,
    bool isPin = false,
    String? errorText,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),

          SizedBox(height: 4.h),

          TextField(
            controller: controller,
            obscureText: isObscure,
            keyboardType: isPin ? TextInputType.number : TextInputType.text,
            maxLength: isPin ? 4 : null,
            decoration: InputDecoration(
              hintText: hint,
              counterText: "",
              errorText: errorText,

              filled: true,
              fillColor: Colors.grey.shade50,

              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: primaryPurple),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
