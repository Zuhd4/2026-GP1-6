import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentChangePasswordPage extends StatefulWidget {
  const ParentChangePasswordPage({super.key});

  @override
  State<ParentChangePasswordPage> createState() =>
      _ParentChangePasswordPageState();
}

class _ParentChangePasswordPageState extends State<ParentChangePasswordPage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isUpdating = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _currentError = null;
      _newError = null;
      _confirmError = null;
    });

    bool hasError = false;

    if (_currentPassController.text.isEmpty) {
      setState(() => _currentError = "Current password required");
      hasError = true;
    }

    if (_newPassController.text.isEmpty) {
      setState(() => _newError = "Password is required");
      hasError = true;
    } else if (_newPassController.text.length < 8) {
      setState(() => _newError = "Min. 8 characters");
      hasError = true;
    } else if (!RegExp(r'[A-Z]').hasMatch(_newPassController.text)) {
      setState(() => _newError = "Must contain 1 uppercase letter");
      hasError = true;
    } else if (!RegExp(r'[a-z]').hasMatch(_newPassController.text)) {
      setState(() => _newError = "Must contain 1 lowercase letter");
      hasError = true;
    }

    if (_confirmPassController.text.isEmpty) {
      setState(() => _confirmError = "Please confirm password");
      hasError = true;
    } else if (_newPassController.text != _confirmPassController.text) {
      setState(() => _confirmError = "Passwords do not match");
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isUpdating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPassController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassController.text.trim());

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentError = "Incorrect current password");
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: green, size: 36.r),
            ),
            SizedBox(height: 16.h),
            Text(
              "Password Updated!",
              style: GoogleFonts.montserrat(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Your password has been changed successfully.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12.sp,
                color: Colors.black45,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  "Done",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? error,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.montserrat(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        onChanged: (_) {
          if (error != null) {
            setState(() {
              _currentError = null;
              _newError = null;
              _confirmError = null;
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12.sp,
            color: error != null ? Colors.redAccent : Colors.black38,
          ),
          errorStyle: GoogleFonts.montserrat(
            fontSize: 10.sp,
            color: Colors.redAccent,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: primaryPurple.withOpacity(0.6),
            size: 20.r,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.black38,
              size: 18.r,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: primaryPurple.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 40.w,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.r,
                color: textDark,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Change Password",
                style: GoogleFonts.montserrat(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 32.h),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_reset_rounded,
                              color: primaryPurple,
                              size: 46.r,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              "Keep your account safe",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Enter your current password, then choose a new one.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 12.sp,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _buildPasswordField(
                        label: "Current Password",
                        controller: _currentPassController,
                        obscure: _obscureCurrent,
                        error: _currentError,
                        onToggle: () {
                          setState(() => _obscureCurrent = !_obscureCurrent);
                        },
                      ),
                      _buildPasswordField(
                        label: "New Password",
                        controller: _newPassController,
                        obscure: _obscureNew,
                        error: _newError,
                        onToggle: () {
                          setState(() => _obscureNew = !_obscureNew);
                        },
                      ),
                      _buildPasswordField(
                        label: "Confirm New Password",
                        controller: _confirmPassController,
                        obscure: _obscureConfirm,
                        error: _confirmError,
                        onToggle: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                      SizedBox(height: 18.h),
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: primaryPurple.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                          ),
                          child: _isUpdating
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Change Password",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
