import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_profile_edit_page.dart';
import 'parent_privacy_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  Widget _avatarImage(String? path, {double size = 96, double radius = 28}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius.r),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius.r),
        child: src.endsWith('.svg')
            ? SvgPicture.asset(src, fit: BoxFit.contain)
            : Image.asset(src, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? '';

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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};

            final String name = data['name']?.toString() ?? 'Parent';
            final String avatar =
                data['avatarUrl']?.toString() ?? 'assets/lexiaAv.png';
            final String email =
                data['email']?.toString() ?? currentUser?.email ?? '';
            final String pin = data['pin']?.toString() ?? '0000';

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 100.h),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 32.h),

                    _sectionHeader("Profile"),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 24.h,
                      ),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _avatarImage(avatar, size: 96.r, radius: 28),
                          SizedBox(height: 12.h),

                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),

                          if (email.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.black38,
                              ),
                            ),
                          ],

                          SizedBox(height: 22.h),
                          const Divider(height: 1, color: Color(0xFFF8F9FB)),
                          SizedBox(height: 12.h),

                          _accountDetailTile(
                            icon: Icons.person_outline_rounded,
                            title: "Profile",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParentProfileEditPage(
                                    initialName: name,
                                    initialAvatar: avatar,
                                    email: email,
                                  ),
                                ),
                              );
                            },
                          ),

                          const Divider(height: 22, color: Color(0xFFF8F9FB)),

                          _accountDetailTile(
                            icon: Icons.privacy_tip_outlined,
                            title: "Privacy",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ParentPrivacyPage(currentPin: pin),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              "Profile & Settings",
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

  Widget _sectionHeader(String title) => Padding(
    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
    child: Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: textDark.withOpacity(0.4),
        letterSpacing: 0.5,
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.025),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _accountDetailTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(9.r),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: primaryPurple.withOpacity(0.75), size: 20.r),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.black26,
        size: 22.r,
      ),
      onTap: onTap,
    );
  }
}
