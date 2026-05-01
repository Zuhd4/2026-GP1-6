import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'change_pin_page.dart';

class ChildProfileSettingsPage extends StatefulWidget {
  final String childId;
  final String initialName;
  final String initialAvatar;

  const ChildProfileSettingsPage({
    super.key,
    required this.childId,
    required this.initialName,
    required this.initialAvatar,
  });

  @override
  State<ChildProfileSettingsPage> createState() =>
      _ChildProfileSettingsPageState();
}

class _ChildProfileSettingsPageState extends State<ChildProfileSettingsPage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  late TextEditingController _nameController;
  late TextEditingController _pinController;
  late String _selectedAvatar;

  bool _isSaving = false;
  bool _allowChildPin = false;

  String? _nameError;

  final List<String> _avatars = [
    'assets/lexiaAv.png',
    'assets/avatars/fox.svg',
    'assets/avatars/bunny.svg',
    'assets/avatars/bear.svg',
    'assets/avatars/penguin.svg',
    'assets/avatars/cat.svg',
    'assets/avatars/lion.svg',
    'assets/avatars/owl.svg',
    'assets/avatars/panda.svg',
    'assets/avatars/dino.svg',
    'assets/avatars/monkey.svg',
    'assets/avatars/witch.svg',
    'assets/avatars/alien.svg',
    'assets/avatars/robot.svg',
    'assets/avatars/monster.svg',
    'assets/avatars/astro.svg',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _pinController = TextEditingController();
    _selectedAvatar = widget.initialAvatar;

    _loadPinSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadPinSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(widget.childId)
          .get();

      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        _allowChildPin = data['allowChildPin'] == true;
        _pinController.text = data['childPin']?.toString() ?? '';
      });
    } catch (e) {
      debugPrint("Failed to load child PIN settings: $e");
    }
  }

  Widget _avatarWidget(String path, {double size = 50}) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(path, width: size, height: size, fit: BoxFit.cover);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    setState(() {
      _nameError = null;
    });

    if (name.isEmpty) {
      setState(() => _nameError = "Name can't be empty");
      return;
    }

    if (name.length < 2) {
      setState(() => _nameError = "Name is too short");
      return;
    }

    if (name.length > 12) {
      setState(() => _nameError = "Max 12 characters");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(widget.childId)
          .update({
            'name': name,
            'avatarUrl': _selectedAvatar,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Oops! Something went wrong. Please try again.",
              style: GoogleFonts.montserrat(fontSize: 13.sp),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF59A685),
                size: 36.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Profile Updated!",
              style: GoogleFonts.montserrat(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Your changes have been saved successfully.",
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
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
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.montserrat(
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      color: textDark.withOpacity(0.4),
      letterSpacing: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currentChildPin = _pinController.text.trim();

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
              Padding(
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
                          "Edit Profile",
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 32.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 90.r,
                          height: 90.r,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28.r),
                            child: _avatarWidget(_selectedAvatar, size: 90.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      _sectionLabel("Name"),
                      SizedBox(height: 8.h),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _nameController,
                          maxLength: 12,
                          style: GoogleFonts.montserrat(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Enter child's name",
                            hintStyle: GoogleFonts.montserrat(
                              fontSize: 13.sp,
                              color: Colors.black26,
                            ),
                            counterText: "",
                            errorText: _nameError,
                            errorStyle: GoogleFonts.montserrat(
                              fontSize: 10.sp,
                              color: Colors.redAccent,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
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
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_allowChildPin) ...[
                        SizedBox(height: 24.h),
                        _sectionLabel("Child PIN"),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () {
                            final currentPin = _pinController.text.trim();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangePinPage(
                                  title: currentPin.isEmpty
                                      ? "Add child PIN"
                                      : "Update child PIN",
                                  subtitle:
                                      "Use a 4-digit PIN to protect this child profile.",
                                  currentPin: currentPin,
                                  isChild: true,
                                  childId: widget.childId,
                                  isAddingPin: currentPin.isEmpty,
                                ),
                              ),
                            ).then((_) {
                              _loadPinSettings();
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pin_rounded,
                                  color: primaryPurple.withOpacity(0.6),
                                  size: 20.r,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    currentChildPin.isEmpty
                                        ? "Add Child PIN"
                                        : "Change Child PIN",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 15.r,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 24.h),

                      _sectionLabel("Choose Avatar"),
                      SizedBox(height: 12.h),

                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                              ),
                          itemCount: _avatars.length,
                          itemBuilder: (context, index) {
                            final path = _avatars[index];
                            final isSelected = _selectedAvatar == path;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedAvatar = path);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryPurple.withOpacity(0.08)
                                      : const Color(0xFFF8F9FB),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryPurple
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.r),
                                        child: _avatarWidget(path, size: 44.r),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 4.r,
                                        right: 4.r,
                                        child: Container(
                                          width: 16.r,
                                          height: 16.r,
                                          decoration: const BoxDecoration(
                                            color: primaryPurple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 10.r,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 32.h),

                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: primaryPurple.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Save Changes",
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
