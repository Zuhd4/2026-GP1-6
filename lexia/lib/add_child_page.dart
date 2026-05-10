import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({super.key});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final TextEditingController _nameController = TextEditingController();

  String _selectedAvatar = 'assets/lexiaAv.png';
  String? _nameError;
  bool _isSaving = false;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  final List<String> avatars = [
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }

  Future<void> _createChild() async {
    final name = _nameController.text.trim();

    if (_isSaving) return;

    if (name.isEmpty) {
      setState(() {
        _nameError = "Please enter your child's name";
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .add({
              'name': name,
              'avatarUrl': _selectedAvatar,
              'level': 1,
              'allowChildPin': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't create child profile"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _header(BuildContext context) {
    return _buildHeader(context, "New Child Profile");
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
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
              title,
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
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: textDark.withOpacity(0.4),
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Container(
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
                                child: _avatarWidget(
                                  _selectedAvatar,
                                  size: 90.r,
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              "Create a child profile",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Choose an avatar and enter a name.",
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

                      _sectionLabel("Name"),
                      SizedBox(height: 8.h),

                      TextField(
                        controller: _nameController,
                        onChanged: (value) {
                          if (_nameError != null && value.trim().isNotEmpty) {
                            setState(() => _nameError = null);
                          }
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: "Child's Name",
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 13.sp,
                            color: Colors.black26,
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
                          errorText: _nameError,
                          errorStyle: GoogleFonts.montserrat(
                            fontSize: 11.sp,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.2,
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
                          itemCount: avatars.length,
                          itemBuilder: (context, index) {
                            final path = avatars[index];
                            final bool isSelected = _selectedAvatar == path;

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
                          onPressed: _isSaving ? null : _createChild,
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
                                  "Create Account",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
