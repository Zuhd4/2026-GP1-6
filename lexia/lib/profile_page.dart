import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_page.dart';
import 'add_child_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);

  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  final User? currentUser = FirebaseAuth.instance.currentUser;

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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20.h),
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 60.r),
            SizedBox(height: 20.h),
            Text(
              "Success!",
              style: GoogleFonts.montserrat(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "Your password has been changed successfully.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13.sp,
                color: Colors.black45,
              ),
            ),
            SizedBox(height: 25.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
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

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    String? currentError;
    String? newError;
    String? confirmError;
    bool isUpdating = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          title: Text(
            "Change Password",
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: textDark,
              fontSize: 18.sp,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                "Current Password",
                currentPassController,
                isObscure: obscureCurrent,
                error: currentError,
                suffixIcon: IconButton(
                  onPressed: () {
                    setDialogState(() {
                      obscureCurrent = !obscureCurrent;
                    });
                  },
                  icon: Icon(
                    obscureCurrent
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.black38,
                    size: 18.r,
                  ),
                ),
              ),
              _buildDialogField(
                "New Password",
                newPassController,
                isObscure: true,
                error: newError,
              ),
              _buildDialogField(
                "Confirm New Password",
                confirmPassController,
                isObscure: true,
                error: confirmError,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.montserrat(
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                onPressed: isUpdating
                    ? null
                    : () async {
                        setDialogState(() {
                          currentError = null;
                          newError = null;
                          confirmError = null;
                        });

                        bool hasError = false;
                        if (currentPassController.text.isEmpty) {
                          setDialogState(
                            () => currentError = "Current password required",
                          );
                          hasError = true;
                        }
                        if (newPassController.text.isEmpty) {
                          setDialogState(
                            () => newError = "Password is required",
                          );
                          hasError = true;
                        } else if (newPassController.text.length < 8) {
                          setDialogState(() => newError = "Min. 8 characters");
                          hasError = true;
                        } else if (!RegExp(
                          r'[A-Z]',
                        ).hasMatch(newPassController.text)) {
                          setDialogState(
                            () => newError = "Must contain 1 uppercase letter",
                          );
                          hasError = true;
                        } else if (!RegExp(
                          r'[a-z]',
                        ).hasMatch(newPassController.text)) {
                          setDialogState(
                            () => newError = "Must contain 1 lowercase letter",
                          );
                          hasError = true;
                        }
                        if (confirmPassController.text.isEmpty) {
                          setDialogState(
                            () => confirmError = "Please confirm password",
                          );
                          hasError = true;
                        } else if (newPassController.text !=
                            confirmPassController.text) {
                          setDialogState(
                            () => confirmError = "Passwords do not match",
                          );
                          hasError = true;
                        }

                        if (hasError) return;

                        setDialogState(() => isUpdating = true);
                        try {
                          AuthCredential credential =
                              EmailAuthProvider.credential(
                                email: currentUser!.email!,
                                password: currentPassController.text.trim(),
                              );
                          await currentUser!.reauthenticateWithCredential(
                            credential,
                          );
                          await currentUser!.updatePassword(
                            newPassController.text.trim(),
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            _showSuccessDialog();
                          }
                        } catch (e) {
                          setDialogState(
                            () => currentError = "Incorrect current password",
                          );
                        } finally {
                          if (mounted) setDialogState(() => isUpdating = false);
                        }
                      },
                child: isUpdating
                    ? SizedBox(
                        height: 18.r,
                        width: 18.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Change",
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

  Widget _buildDialogField(
    String label,
    TextEditingController controller, {
    bool isObscure = false,
    String? error,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.montserrat(fontSize: 13.sp),
        decoration: InputDecoration(
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 11.sp,
            color: error != null ? Colors.redAccent : Colors.black38,
            fontWeight: error != null ? FontWeight.w600 : FontWeight.w400,
          ),
          errorText: error,
          errorStyle: GoogleFonts.montserrat(
            fontSize: 9.sp,
            color: Colors.redAccent,
            height: 0.8,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = currentUser?.uid ?? "";

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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }

            final userData =
                userSnap.data?.data() as Map<String, dynamic>? ?? {};

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 100.h),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 20.h),
                    _sectionHeader("Account"),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 15.h,
                      ),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          Center(
                            child: Column(
                              children: [
                                _avatarImage(
                                  userData['avatarUrl'],
                                  size: 80.r,
                                  radius: 24,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  userData['name'] ?? "Parent",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w500,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  userData['email'] ?? "",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11.sp,
                                    color: Colors.black38,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 30, color: Color(0xFFF8F9FB)),
                          _accountDetailTile(
                            Icons.person_outline_rounded,
                            "Display Name",
                            userData['name'] ?? "",
                          ),
                          _accountDetailTile(
                            Icons.email_outlined,
                            "Email Address",
                            userData['email'] ?? "",
                          ),
                          _accountDetailTile(
                            Icons.lock_reset_rounded,
                            "Change Password",
                            "••••••••",
                            isAction: true,
                            onTap: _showChangePasswordDialog,
                          ),
                          _accountDetailTile(
                            Icons.lock_outline_rounded,
                            "Parental PIN",
                            userData['pin']?.toString() ?? "Not Set",
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
                                data['name'],
                                data['avatarUrl'],
                                doc.id,
                              );
                            }),
                            _addChildButton(),
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
                      _signOut,
                      isOutlined: true,
                    ),
                    SizedBox(height: 12.h),
                    _actionButton(
                      "Delete Account",
                      Icons.delete_forever_rounded,
                      const Color(0xFFD32F2F).withOpacity(0.8),
                      _confirmDelete,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _accountDetailTile(
    IconData icon,
    String title,
    String value, {
    bool isAction = false,
    VoidCallback? onTap,
  }) => ListTile(
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
    trailing: isAction
        ? Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20.r)
        : null,
    onTap: onTap,
  );

  Widget _childCard(String name, String? avatar, String id) => Container(
    margin: EdgeInsets.only(bottom: 12.h),
    padding: EdgeInsets.all(12.w),
    decoration: _cardDecoration(),
    child: Row(
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
          onPressed: () => _confirmDeleteChild(name, id),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent.withOpacity(0.6),
            size: 20.r,
          ),
        ),
      ],
    ),
  );

  Widget _addChildButton() => InkWell(
    onTap: () =>
        showDialog(context: context, builder: (_) => const AddChildPage()),
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
  }) => SizedBox(
    width: double.infinity,
    height: 54.h,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18.r),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          "Sign Out",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
        content: Text(
          "Are you sure you want to sign out?",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.montserrat(
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                  (r) => false,
                );
              }
            },
            child: Text(
              "Sign Out",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChild(String name, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          "Delete $name?",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
        ),
        content: Text(
          "Are you sure you want to remove this profile? All progress will be lost.",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.montserrat(
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('children')
                    .doc(id)
                    .delete();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error deleting child: $e")),
                );
              }
            },
            child: Text(
              "Delete",
              style: GoogleFonts.montserrat(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          "Delete Account?",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
        ),
        content: Text(
          "This will permanently delete your account and all family data.",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.montserrat(
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                final String currentUid = currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUid)
                    .delete();
                await currentUser!.delete();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingPage()),
                    (r) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Security: Please re-login before deleting your account.",
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text(
              "Delete",
              style: GoogleFonts.montserrat(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
