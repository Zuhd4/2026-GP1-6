import 'auth_identity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'profile_selection.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_typography.dart';
import 'child_profile_settings_page.dart';

class ChildProfilePage extends StatefulWidget {
  final String childId;

  const ChildProfilePage({super.key, required this.childId});

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  bool _isExiting = false;
  String get childId => widget.childId;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  Widget _avatarImage(String? path, {double size = 80, double radius = 24}) {
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

  Widget _buildHeader(BuildContext context, bool useOpenDyslexic) {
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
              "Child Profile",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
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

  Widget _sectionHeader(String title, bool useOpenDyslexic) => Padding(
    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
    child: Text(
      title,
      style: AppTypography.getStyle(
        useOpenDyslexic: useOpenDyslexic,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: textDark.withOpacity(0.4),
        letterSpacing: 0.5,
      ),
    ),
  );

  // Leave the child session, but keep this family's selection flow.
  Future<void> _exitToProfiles() async {
    if (_isExiting) return;
    setState(() => _isExiting = true);

    try {
      // Wait until the on-page overlay replaces Firestore StreamBuilders.
      // This releases child document listeners before Firebase sign-out.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final code = AuthIdentity.familyCode;
      if (code == null || code.isEmpty) {
        throw StateError('Family Code unavailable.');
      }

      final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('verifyFamilyCode')
          .call<Map<String, dynamic>>({'familyCode': code});
      final profiles = (result.data['profiles'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      await FirebaseAuth.instance.signOut();
      AuthIdentity.clearChild();
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              ProfileSelectionPage(familyCode: code, profiles: profiles),
        ),
        (_) => false,
      );
    } catch (e) {
      debugPrint('Exit to child profiles failed: $e');
      if (!mounted) return;
      setState(() => _isExiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open profiles. Please try again.'),
        ),
      );
    }
  }

  Widget _exitingOverlay() {
    return Scaffold(
      backgroundColor: ivoryWhite,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 30.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: primaryPurple),
                  SizedBox(height: 18.h),
                  Text(
                    'Exiting...',
                    style: AppTypography.getStyle(
                      useOpenDyslexic: false,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isExiting) return _exitingOverlay();
    final String uid = AuthIdentity.parentUid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(widget.childId)
          .snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};
        final bool useOpenDyslexic = userData['useOpenDyslexicFont'] == true;

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
                  .collection('children')
                  .doc(childId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryPurple),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      "Child profile not found",
                      style: AppTypography.getStyle(
                        useOpenDyslexic: useOpenDyslexic,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  );
                }

                final data = snapshot.data!.data() ?? {};
                final String name = data['name']?.toString() ?? 'Child';
                final String avatar =
                    data['avatarUrl']?.toString() ?? 'assets/lexiaAv.png';

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 100.h),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, useOpenDyslexic),
                        SizedBox(height: 20.h),

                        _sectionHeader("Profile", useOpenDyslexic),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 22.h,
                          ),
                          decoration: _cardDecoration(),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        _avatarImage(
                                          avatar,
                                          size: 90.r,
                                          radius: 26,
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          name,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.getStyle(
                                            useOpenDyslexic: useOpenDyslexic,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChildProfileSettingsPage(
                                              childId: childId,
                                              initialName: name,
                                              initialAvatar: avatar,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: primaryPurple.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: primaryPurple.withOpacity(0.7),
                                      size: 18.r,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton.icon(
                            onPressed: _isExiting ? null : _exitToProfiles,
                            icon: Icon(Icons.logout_rounded, size: 24.r),
                            label: Text(
                              'Exit',
                              style: AppTypography.getStyle(
                                useOpenDyslexic: useOpenDyslexic,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: primaryPurple,
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
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
        );
      },
    );
  }
}
