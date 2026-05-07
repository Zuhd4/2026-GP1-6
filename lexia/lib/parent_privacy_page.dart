import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/lexia_popup.dart';
import 'onboarding_page.dart';
import 'add_child_page.dart';
import 'child_profile_settings_page.dart';
import 'parent_change_password_page.dart';
import 'change_pin_page.dart';

class ParentPrivacyPage extends StatelessWidget {
  final String currentPin;

  const ParentPrivacyPage({super.key, required this.currentPin});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  Widget _avatarImage(String? path, {double size = 50, double radius = 12}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius.r),
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
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 100.h),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context),
                SizedBox(height: 20.h),

                _sectionHeader("Security"),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _detailTile(
                        icon: Icons.lock_reset_rounded,
                        title: "Password",
                        value: "••••••••",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentChangePasswordPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 24, color: Color(0xFFF8F9FB)),
                      _detailTile(
                        icon: Icons.lock_outline_rounded,
                        title: "Parental PIN",
                        value: "••••",
                        onTap: () async {
                          final String uid =
                              FirebaseAuth.instance.currentUser?.uid ?? '';

                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();

                          final latestPin =
                              userDoc.data()?['pin']?.toString() ?? currentPin;

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangePinPage(
                                  title: "Update your parental PIN",
                                  subtitle:
                                      "Use a 4-digit PIN to protect parent-only actions.",
                                  currentPin: latestPin,
                                  isChild: false,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                _sectionHeader("My Family"),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('children')
                      .snapshots(),
                  builder: (context, childSnap) {
                    final children = childSnap.data?.docs ?? [];

                    return Column(
                      children: [
                        ...children.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return _childCard(
                            context,
                            data['name'] ?? 'Child',
                            data['avatarUrl'],
                            doc.id,
                          );
                        }),
                        _addChildButton(context),
                      ],
                    );
                  },
                ),

                SizedBox(height: 25.h),

                _sectionHeader("Account Actions"),
                _actionButton(
                  "Sign Out",
                  Icons.logout_rounded,
                  primaryPurple,
                  () => _signOut(context),
                  isOutlined: true,
                ),
                SizedBox(height: 12.h),
                _actionButton(
                  "Delete Account",
                  Icons.delete_forever_rounded,
                  const Color(0xFFD32F2F).withOpacity(0.8),
                  () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
              "Privacy",
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
    borderRadius: BorderRadius.circular(24.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: primaryPurple.withOpacity(0.7), size: 18.r),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 10.sp,
          color: Colors.black38,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.montserrat(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.black26,
        size: 20.r,
      ),
      onTap: onTap,
    );
  }

  Widget _childCard(
    BuildContext context,
    String name,
    String? avatar,
    String id,
  ) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final bool allowChildPin = data['allowChildPin'] == true;
        final String childPin = data['childPin']?.toString() ?? '';

        final bool childPinEnabled =
            data['childPinEnabled'] == true ||
            (data['childPinEnabled'] == null && childPin.isNotEmpty);

        final String permissionStatus = allowChildPin
            ? "PIN allowed"
            : "PIN not allowed";

        final String childLockStatus = childPin.isEmpty
            ? "No PIN added yet"
            : childPinEnabled
            ? "Child turned PIN on"
            : "Child turned PIN off";

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  _avatarImage(avatar, size: 48.r, radius: 14),
                  SizedBox(width: 14.w),

                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        color: textDark,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildProfileSettingsPage(
                            childId: id,
                            initialName: name,
                            initialAvatar: avatar ?? 'assets/lexiaAv.png',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18.r,
                      color: primaryPurple.withOpacity(0.7),
                    ),
                  ),

                  IconButton(
                    onPressed: () =>
                        _confirmDeleteChild(context, name, id, uid),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent.withOpacity(0.6),
                      size: 20.r,
                    ),
                  ),
                ],
              ),

              const Divider(height: 22, color: Color(0xFFF8F9FB)),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.pin_rounded,
                            color: primaryPurple.withOpacity(0.7),
                            size: 18.r,
                          ),
                        ),
                        SizedBox(width: 12.w),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Child PIN Permission",
                                style: GoogleFonts.montserrat(
                                  fontSize: 10.sp,
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                permissionStatus,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        GestureDetector(
                          onTap: () async {
                            final bool newAllowValue = !allowChildPin;

                            final Map<String, dynamic> updateData = {
                              'allowChildPin': newAllowValue,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (!newAllowValue) {
                              updateData['childPinEnabled'] = false;
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('children')
                                .doc(id)
                                .set(updateData, SetOptions(merge: true));

                            if (context.mounted) {
                              LexiaPopup.showMessage(
                                context: context,
                                title: newAllowValue
                                    ? "Child PIN Allowed"
                                    : "Child PIN Disabled",
                                message: newAllowValue
                                    ? "$name can now add or use a PIN for this profile."
                                    : "$name can enter the profile without a PIN. The saved PIN was not deleted.",
                                icon: newAllowValue
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                iconColor: primaryPurple,
                                buttonColor: primaryPurple,
                                buttonText: "Got it",
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 54.w,
                            height: 30.h,
                            padding: EdgeInsets.all(3.r),
                            decoration: BoxDecoration(
                              color: allowChildPin
                                  ? primaryPurple
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: allowChildPin
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 24.r,
                                height: 24.r,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  allowChildPin
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  size: 15.r,
                                  color: allowChildPin
                                      ? primaryPurple
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (allowChildPin) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: primaryPurple.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              childPinEnabled
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 18.r,
                              color: childPinEnabled
                                  ? primaryPurple.withOpacity(0.75)
                                  : Colors.black45,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                childLockStatus,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11.sp,
                                  color: childPinEnabled
                                      ? textDark.withOpacity(0.75)
                                      : Colors.black45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (allowChildPin && childPin.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: primaryPurple.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.password_rounded,
                              size: 18.r,
                              color: primaryPurple.withOpacity(0.7),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              "Selected PIN",
                              style: GoogleFonts.montserrat(
                                fontSize: 11.sp,
                                color: Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              childPin,
                              style: GoogleFonts.montserrat(
                                fontSize: 14.sp,
                                color: textDark,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addChildButton(BuildContext context) => InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddChildPage()),
      );
    },
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: primaryPurple.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            color: primaryPurple.withOpacity(0.6),
            size: 18.r,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              "Add Child Profile",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                color: primaryPurple.withOpacity(0.7),
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18.r),
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          elevation: isOutlined ? 0 : 4,
          shadowColor: color.withOpacity(0.2),
          side: isOutlined
              ? BorderSide(color: color.withOpacity(0.2))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  void _signOut(BuildContext context) async {
    final shouldSignOut = await LexiaPopup.showConfirm(
      context: context,
      title: "Sign Out",
      message: "Are you sure you want to sign out?",
      confirmText: "Sign Out",
      confirmColor: primaryPurple,
      icon: Icons.logout_rounded,
      iconColor: primaryPurple,
    );

    if (!shouldSignOut) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'sessionActive': false,
        'signedOutAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (r) => false,
      );
    }
  }

  void _confirmDeleteChild(
    BuildContext context,
    String name,
    String id,
    String uid,
  ) async {
    final shouldDelete = await LexiaPopup.showConfirm(
      context: context,
      title: "Delete $name?",
      message:
          "Are you sure you want to remove this profile? All progress will be lost.",
      confirmText: "Delete",
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.redAccent,
    );

    if (shouldDelete) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(id)
          .delete();
    }
  }

  void _confirmDelete(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    final shouldDelete = await LexiaPopup.showConfirm(
      context: context,
      title: "Delete Account?",
      message: "This will permanently delete your account and all family data.",
      confirmText: "Delete",
      confirmColor: Colors.redAccent,
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
    );

    if (!shouldDelete) return;

    try {
      final uid = user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await user.delete();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
          (r) => false,
        );
      }
    } catch (_) {
      if (context.mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: "Security Required",
          message: "Please re-login before deleting your account.",
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.redAccent,
          buttonColor: primaryPurple,
          buttonText: "Got it",
        );
      }
    }
  }
}
