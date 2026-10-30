import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/lexia_popup.dart';
import 'onboarding_page.dart';
import 'add_child_page.dart';
import 'child_profile_settings_page.dart';
import 'parent_change_password_page.dart';
import 'widgets/family_code_card.dart';

class ParentPrivacyPage extends StatelessWidget {
  // Kept optional for compatibility with older navigation callers.
  const ParentPrivacyPage({super.key, String? currentPin});

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

                // Parent controls OpenDyslexic separately for each child.
                _sectionHeader("Accessibility"),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('children')
                      .snapshots(),
                  builder: (context, childSnap) {
                    final children = childSnap.data?.docs ?? [];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (children.isEmpty)
                            Text(
                              'Add a child to choose their font.',
                              style: GoogleFonts.montserrat(
                                fontSize: 11.sp,
                                color: Colors.black45,
                              ),
                            )
                          else ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: primaryPurple.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.accessibility_new_rounded,
                                    color: primaryPurple.withValues(alpha: 0.7),
                                    size: 18.r,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dyslexia Friendly Font',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                          color: textDark,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Choose children below',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10.sp,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 26.h,
                              color: const Color(0xFFF0ECF8),
                            ),
                            Text(
                              'Choose individually',
                              style: GoogleFonts.montserrat(
                                fontSize: 11.sp,
                                color: Colors.black45,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ...children.map((child) {
                              final childData = child.data();
                              final name = (childData['name'] ?? 'Child')
                                  .toString();
                              final enabled =
                                  childData['useOpenDyslexicFont'] == true;
                              return Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: _fontPreferenceTile(
                                  context,
                                  title: name,
                                  subtitle: enabled
                                      ? 'OpenDyslexic'
                                      : 'Standard font',
                                  avatar: childData['avatarUrl']?.toString(),
                                  enabled: enabled,
                                  onTap: () => _confirmChildFont(
                                    context,
                                    uid,
                                    child.id,
                                    name,
                                    !enabled,
                                  ),
                                ),
                              );
                            }),
                          ],
                          SizedBox(height: 10.h),
                          Text(
                            'Dyslexia Friendly Font applies to menus and instructions for selected children. Target vocabulary words stay standard.',
                            style: GoogleFonts.montserrat(
                              fontSize: 10.sp,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

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

                SizedBox(height: 15.h),
                const FamilyCodeCard(),

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

  Widget _fontPreferenceTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback? onTap,
    String? avatar,
    IconData icon = Icons.font_download_rounded,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(
          children: [
            if (avatar != null)
              _avatarImage(avatar, size: 37.r, radius: 10)
            else
              Container(
                width: 37.r,
                height: 37.r,
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: primaryPurple, size: 19.r),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 10.sp,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            IgnorePointer(
              child: Switch(
                value: enabled,
                onChanged: onTap == null ? null : (_) {},
                activeThumbColor: primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setChildFont(
    BuildContext context,
    String parentUid,
    String childId,
    bool enabled,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .update({'useOpenDyslexicFont': enabled});
    } catch (_) {
      if (context.mounted) {
        await LexiaPopup.showMessage(
          context: context,
          title: 'Could not save',
          message: 'Please try again.',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
          buttonColor: primaryPurple,
        );
      }
    }
  }

  Future<void> _confirmChildFont(
    BuildContext context,
    String parentUid,
    String childId,
    String childName,
    bool enabled,
  ) async {
    final confirmed = await LexiaPopup.showConfirm(
      context: context,
      title: enabled
          ? 'Enable Dyslexia Friendly Font?'
          : 'Disable Dyslexia Friendly Font?',
      message: enabled
          ? 'Apply Dyslexia Friendly Font to $childName?'
          : 'Use the standard font for $childName?',
      confirmText: enabled ? 'Enable' : 'Disable',
      cancelText: 'Cancel',
      icon: Icons.font_download_rounded,
      iconColor: primaryPurple,
      confirmColor: primaryPurple,
    );
    if (!confirmed || !context.mounted) return;
    await _setChildFont(context, parentUid, childId, enabled);
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
    final parentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final bool enabled = data['picturePinEnabled'] == true;
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  _avatarImage(avatar, size: 48.r, radius: 14),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit child profile',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChildProfileEditPage(
                          childId: id,
                          initialName: name,
                          initialAvatar: avatar ?? 'assets/lexiaAv.png',
                          openedByParent: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, color: primaryPurple),
                  ),
                  IconButton(
                    tooltip: 'Delete child profile',
                    onPressed: () =>
                        _confirmDeleteChild(context, name, id, parentUid),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const Divider(height: 22, color: Color(0xFFF8F9FB)),
              Row(
                children: [
                  Icon(
                    enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: primaryPurple,
                    size: 19.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Picture PIN',
                          style: GoogleFonts.montserrat(
                            color: textDark,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          enabled ? 'PIN is set' : 'PIN not set',
                          style: GoogleFonts.montserrat(
                            color: Colors.black54,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ParentResetPicturePinPage(
                          childId: id,
                          childName: name,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(enabled ? 'Reset PIN' : 'Set PIN'),
                  ),
                ],
              ),
              _ParentPinRecoveryView(
                key: ValueKey('pin-$id-${data['picturePinUpdatedAt']}'),
                childId: id,
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

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await LexiaPopup.showConfirm(
      context: context,
      title: "Sign Out",
      message: "Are you sure you want to sign out?",
      confirmText: "Sign Out",
      confirmColor: primaryPurple,
      icon: Icons.logout_rounded,
      iconColor: primaryPurple,
    );

    if (!shouldSignOut || !context.mounted) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'sessionActive': false,
          'signedOutAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      if (!context.mounted) return;
      await LexiaPopup.showMessage(
        context: context,
        title: 'Sign Out Failed',
        message: 'Could not update the session. Please try again.',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        buttonColor: primaryPurple,
      );
      return;
    }

    if (!context.mounted) return;

    // Remove all parent pages (and their Firestore listeners) before sign-out.
    // A zero-duration route avoids leaving old pages active during animation.
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const _ParentSignOutTransition(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  Future<void> _confirmDeleteChild(
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

    if (!shouldDelete || !context.mounted) return;

    // A Cloud Function removes the child document AND all subcollections,
    // its uploaded files, and the dedicated child Firebase Auth account.
    // A plain document.delete() leaves orphaned privateAuth documents.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(color: primaryPurple),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  'Deleting child profile...',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.sp,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    String? failure;
    try {
      final signedInUid = FirebaseAuth.instance.currentUser?.uid;
      if (signedInUid == null || signedInUid != uid) {
        throw StateError('Parent sign-in required.');
      }
      await FirebaseFunctions.instanceFor(
        region: 'me-central1',
      ).httpsCallable('deleteChildProfile').call({'childId': id});
    } on FirebaseFunctionsException catch (e) {
      failure = e.message ?? 'Could not delete this child profile.';
    } catch (e) {
      failure = 'Could not delete this child profile. Please try again.';
      debugPrint('DELETE CHILD ERROR: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (failure != null) {
      await LexiaPopup.showMessage(
        context: context,
        title: 'Deletion Not Completed',
        message: failure,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        buttonColor: primaryPurple,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      if (!context.mounted) return;
      await LexiaPopup.showMessage(
        context: context,
        title: 'Sign In Required',
        message: 'Please sign in as a parent to delete the account.',
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.redAccent,
        buttonColor: primaryPurple,
      );
      return;
    }

    final shouldDelete = await LexiaPopup.showConfirm(
      context: context,
      title: 'Delete Account?',
      message: 'This will permanently delete your account and all family data.',
      confirmText: 'Delete',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
    );

    if (!shouldDelete || !context.mounted) return;

    final verified = await _confirmDeletionPassword(context, user);
    if (verified != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(color: primaryPurple),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  'Deleting family account...',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.sp,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    String? failure;

    try {
      await FirebaseFunctions.instanceFor(
        region: 'me-central1',
      ).httpsCallable('deleteFamilyAccount').call({});
    } on FirebaseFunctionsException catch (e) {
      failure = e.message ?? 'Account deletion could not be completed.';
    } catch (_) {
      failure = 'Could not complete account deletion. Please try again.';
    }

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (failure != null) {
      await LexiaPopup.showMessage(
        context: context,
        title: 'Deletion Not Completed',
        message: failure,
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        buttonColor: primaryPurple,
      );
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (route) => false,
    );
  }

  Future<bool?> _confirmDeletionPassword(
    BuildContext context,
    User user,
  ) async {
    final controller = TextEditingController();
    bool hidePassword = true;
    bool verifying = false;
    String? error;

    try {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            title: Text(
              'Confirm Your Password',
              style: GoogleFonts.montserrat(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your parent password to permanently delete your family account.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11.sp,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  enabled: !verifying,
                  obscureText: hidePassword,
                  autofocus: true,
                  onChanged: (_) {
                    if (error != null) update(() => error = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Parent password',
                    errorText: error,
                    errorStyle: GoogleFonts.montserrat(
                      color: Colors.red,
                      fontSize: 10.sp,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    suffixIcon: IconButton(
                      onPressed: verifying
                          ? null
                          : () => update(() => hidePassword = !hidePassword),
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: verifying
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(color: primaryPurple),
                ),
              ),
              ElevatedButton(
                onPressed: verifying
                    ? null
                    : () async {
                        if (controller.text.isEmpty) {
                          update(() => error = 'Field required');
                          return;
                        }

                        update(() {
                          verifying = true;
                          error = null;
                        });

                        try {
                          final credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: controller.text,
                          );

                          await user.reauthenticateWithCredential(credential);
                          await user.getIdToken(true);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } on FirebaseAuthException catch (e) {
                          if (dialogContext.mounted) {
                            update(() {
                              error = e.code == 'network-request-failed'
                                  ? 'Network error. Please try again.'
                                  : 'Incorrect password. Please try again.';
                              verifying = false;
                            });
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            update(() {
                              error = 'Unable to verify password.';
                              verifying = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: verifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Delete Account',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
  }
}

// Displays the saved picture sequence automatically to the signed-in parent.
// Only the parent-authenticated Cloud Function can decrypt the private copy.
class _ParentPinRecoveryView extends StatefulWidget {
  final String childId;
  const _ParentPinRecoveryView({super.key, required this.childId});

  @override
  State<_ParentPinRecoveryView> createState() => _ParentPinRecoveryViewState();
}

class _ParentPinRecoveryViewState extends State<_ParentPinRecoveryView> {
  static const purple = Color(0xFF6A5ACD);
  List<int>? _pictures;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadPictures();
  }

  Future<void> _loadPictures() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _message = null;
        _pictures = null;
      });
    }
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('manageChildPin')
          .call({'action': 'getRecovery', 'childId': widget.childId});
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      if (data['available'] == true && data['sequence'] is List) {
        final values = List<int>.from(data['sequence'] as List);
        if (values.length != 3 || values.any((n) => n < 1 || n > 9)) {
          throw StateError('Unexpected PIN data.');
        }
        setState(() {
          _pictures = values;
        });
      } else {
        setState(() {
          _message =
              'Reset this PIN once to display the three pictures. Existing PINs saved before recovery was enabled cannot be recovered.';
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted)
        setState(() {
          _message = e.message ?? e.code;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _message = 'Unable to load the Picture PIN.';
        });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading Picture PIN...'),
              ],
            )
          else if (_pictures != null) ...[
            const Text(
              'Selected pictures (in order)',
              style: TextStyle(color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _pictures!
                  .asMap()
                  .entries
                  .map(
                    (entry) => Container(
                      width: 75,
                      height: 85,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EFFF),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFE3DDF6)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${entry.key + 1}',
                            style: const TextStyle(fontSize: 11, color: purple),
                          ),
                          Expanded(
                            child: Image.asset(
                              'assets/pin_photos/pin_${entry.value}.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ] else if (_message != null)
            Text(
              _message!,
              style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
            ),
          if (!_loading && _pictures == null && _message != null)
            TextButton.icon(
              onPressed: _loadPictures,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

// Parent-controlled picture PIN replacement, including encrypted recovery.
class _ParentResetPicturePinPage extends StatefulWidget {
  final String childId;
  final String childName;
  const _ParentResetPicturePinPage({
    required this.childId,
    required this.childName,
  });

  @override
  State<_ParentResetPicturePinPage> createState() =>
      _ParentResetPicturePinPageState();
}

class _ParentResetPicturePinPageState
    extends State<_ParentResetPicturePinPage> {
  static const purple = Color(0xFF6A5ACD);
  static const dark = Color(0xFF2D3142);
  final List<int> first = [];
  final List<int> confirmation = [];
  bool confirming = false;
  bool saving = false;
  String? message;

  List<int> get active => confirming ? confirmation : first;

  Future<void> proceed() async {
    if (active.length != 3 || saving) return;
    if (!confirming) {
      setState(() {
        confirming = true;
        confirmation.clear();
        message = null;
      });
      return;
    }
    if (first.join(',') != confirmation.join(',')) {
      setState(() {
        confirmation.clear();
        message = 'The pictures do not match. Please try again.';
      });
      return;
    }
    setState(() {
      saving = true;
      message = null;
    });
    try {
      await FirebaseFunctions.instanceFor(
        region: 'me-central1',
      ).httpsCallable('manageChildPin').call({
        'action': 'reset',
        'childId': widget.childId,
        'newPin': List<int>.from(first),
      });
      if (!mounted) return;
      await LexiaPopup.showMessage(
        context: context,
        title: 'Picture PIN Updated!',
        message: 'The new Picture PIN has been saved successfully.',
        icon: Icons.check_rounded,
        iconColor: const Color(0xFF59A685),
        buttonColor: purple,
        buttonText: 'Got it',
        barrierDismissible: false,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.message ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Could not reset PIN. Please try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          saving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          confirming ? 'Confirm Picture PIN' : 'Reset Picture PIN',
          style: GoogleFonts.montserrat(
            color: dark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Picture PIN for ${widget.childName}',
                style: GoogleFonts.montserrat(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                confirming
                    ? 'Select the same three pictures again in the same order.'
                    : 'Select three pictures in order to replace the existing PIN.',
                style: GoogleFonts.montserrat(color: Colors.black54),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      border: Border.all(color: const Color(0xFFDCD4F8)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: i < active.length
                        ? Image.asset(
                            'assets/pin_photos/pin_${active[i]}.png',
                            fit: BoxFit.contain,
                          )
                        : Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.black38),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, index) => InkWell(
                  onTap: saving || active.length == 3
                      ? null
                      : () {
                          setState(() {
                            active.add(index + 1);
                            message = null;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6FF),
                      border: Border.all(color: const Color(0xFFE3DDF6)),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Image.asset(
                      'assets/pin_photos/pin_${index + 1}.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${active.length}/3 selected',
                    style: const TextStyle(color: purple),
                  ),
                  TextButton(
                    onPressed: saving || active.isEmpty
                        ? null
                        : () {
                            setState(() => active.removeLast());
                          },
                    child: const Text('Undo'),
                  ),
                  TextButton(
                    onPressed: saving || active.isEmpty
                        ? null
                        : () {
                            setState(() => active.clear());
                          },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    message!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: saving || active.length != 3 ? null : proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          confirming ? 'Save New PIN' : 'Next',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                          ),
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

// This temporary screen owns no Firestore listeners. It waits for the parent
// routes to finish disposing before invalidating the Firebase Auth session.
class _ParentSignOutTransition extends StatefulWidget {
  const _ParentSignOutTransition();

  @override
  State<_ParentSignOutTransition> createState() =>
      _ParentSignOutTransitionState();
}

class _ParentSignOutTransitionState extends State<_ParentSignOutTransition> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSignOut());
  }

  Future<void> _finishSignOut() async {
    // The first frame commits the new route; the following frame lets the old
    // parent routes and their StreamBuilders finish disposing.
    await WidgetsBinding.instance.endOfFrame;
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      await LexiaPopup.showMessage(
        context: context,
        title: 'Sign Out Failed',
        message: 'Please check your connection and try again.',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        buttonColor: const Color(0xFF6A5ACD),
      );
      if (mounted) _finishSignOut();
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFFFFF9F9),
    body: Center(child: CircularProgressIndicator(color: Color(0xFF6A5ACD))),
  );
}
