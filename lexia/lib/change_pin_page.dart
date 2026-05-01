import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePinPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String currentPin;
  final bool isChild;
  final String? childId;
  final bool isAddingPin;

  const ChangePinPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentPin,
    required this.isChild,
    this.childId,
    this.isAddingPin = false,
  });

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);

  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isUpdating = false;

  String? _oldPinError;
  String? _newPinError;
  String? _confirmPinError;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    setState(() {
      _oldPinError = null;
      _newPinError = null;
      _confirmPinError = null;
    });

    bool hasError = false;

    if (!widget.isAddingPin) {
      if (_oldPinController.text.isEmpty) {
        _oldPinError = "Current PIN required";
        hasError = true;
      } else if (_oldPinController.text != widget.currentPin) {
        _oldPinError = "Incorrect PIN";
        hasError = true;
      }
    }

    if (_newPinController.text.isEmpty) {
      _newPinError = "New PIN required";
      hasError = true;
    } else if (!RegExp(r'^\d{4}$').hasMatch(_newPinController.text)) {
      _newPinError = "PIN must be 4 numbers";
      hasError = true;
    }

    if (_confirmPinController.text.isEmpty) {
      _confirmPinError = "Please confirm PIN";
      hasError = true;
    } else if (_newPinController.text != _confirmPinController.text) {
      _confirmPinError = "PINs do not match";
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() => _isUpdating = true);

    try {
      if (widget.isChild) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('children')
            .doc(widget.childId)
            .update({
              'childPin': _newPinController.text.trim(),
              'allowChildPin': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'pin': _newPinController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) _showErrorSnack("Couldn't update PIN. Please try again.");
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
              widget.isAddingPin ? "PIN Added!" : "PIN Updated!",
              style: GoogleFonts.montserrat(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.isAddingPin
                  ? "Your PIN has been added successfully."
                  : "Your PIN has been changed successfully.",
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

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontSize: 13.sp)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    String? error,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        style: GoogleFonts.montserrat(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        onChanged: (_) {
          setState(() {
            _oldPinError = null;
            _newPinError = null;
            _confirmPinError = null;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          counterText: "",
          errorText: error,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12.sp,
            color: error != null ? Colors.redAccent : Colors.black38,
          ),
          prefixIcon: Icon(
            Icons.pin_rounded,
            color: primaryPurple.withOpacity(0.6),
            size: 20.r,
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
        ),
      ),
    );
  }

  Widget _header() {
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
                "Change PIN",
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
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
                              Icons.lock_outline_rounded,
                              color: primaryPurple,
                              size: 46.r,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              widget.subtitle,
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
                      if (!widget.isAddingPin)
                        _buildPinField(
                          label: "Current PIN",
                          controller: _oldPinController,
                          error: _oldPinError,
                        ),
                      _buildPinField(
                        label: "New PIN",
                        controller: _newPinController,
                        error: _newPinError,
                      ),
                      _buildPinField(
                        label: "Confirm New PIN",
                        controller: _confirmPinController,
                        error: _confirmPinError,
                      ),
                      SizedBox(height: 18.h),
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _changePin,
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
                                  widget.isAddingPin ? "Add PIN" : "Change PIN",
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
