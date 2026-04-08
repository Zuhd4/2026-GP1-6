import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'onboarding_page.dart';
import 'add_child_popup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color scaffoldBg = Color.fromARGB(255, 249, 247, 248);

  final User? currentUser = FirebaseAuth.instance.currentUser;

  Widget _avatarImage(String? path, {double size = 50, double radius = 12}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD4EFFF),
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

  // --- PASSWORD CHANGE LOGIC ---
  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            "Change Password",
            style: TextStyle(
              fontWeight: FontWeight.w900,
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
                isObscure: true,
              ),
              _buildDialogField(
                "New Password",
                newPassController,
                isObscure: true,
              ),
              _buildDialogField(
                "Confirm New Password",
                confirmPassController,
                isObscure: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (newPassController.text !=
                          confirmPassController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Passwords do not match"),
                          ),
                        );
                        return;
                      }
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Success!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error: Check current password"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } finally {
                        setDialogState(() => isUpdating = false);
                      }
                    },
              child: isUpdating
                  ? SizedBox(
                      height: 20.r,
                      width: 20.r,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Change", style: TextStyle(color: Colors.white)),
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
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting)
            return const SizedBox();
          final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22.w, 60.h, 22.w, 140.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 30.h),

                // 1. ACCOUNT SECTION
                _sectionHeader("Account"),
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            _avatarImage(
                              userData['avatarUrl'],
                              size: 85.r,
                              radius: 22,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              userData['name'] ?? "Parent",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                              ),
                            ),
                            Text(
                              userData['email'] ?? "",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 35, color: Color(0xFFF3F4F8)),
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
                        isAction: false,
                        onTap: null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25.h),

                // 2. MY FAMILY SECTION
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
                SizedBox(height: 35.h),

                // 3. ACCOUNT ACTIONS
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
                  const Color(0xFFD32F2F),
                  _confirmDelete,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.r,
            color: textDark,
          ),
        ),
        const Spacer(),
        Text(
          "Profile & Settings",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: textDark,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w900,
        color: textDark.withOpacity(0.6),
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 10,
        offset: const Offset(0, 4),
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
    leading: Icon(icon, color: primaryPurple, size: 20.r),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 10.sp,
        color: Colors.black38,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      value,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w800,
        color: textDark,
      ),
    ),
    trailing: isAction
        ? Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20.r)
        : null,
    onTap: onTap,
  );

  Widget _childCard(String name, String? avatar, String id) => Container(
    margin: EdgeInsets.only(bottom: 10.h),
    padding: EdgeInsets.all(12.w),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        _avatarImage(avatar, size: 45.r, radius: 12),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _confirmDeleteChild(name, id),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 20.r,
          ),
        ),
      ],
    ),
  );

  Widget _addChildButton() => InkWell(
    onTap: () =>
        showDialog(context: context, builder: (_) => const AddChildPopup()),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: primaryPurple.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            color: primaryPurple,
            size: 18.r,
          ),
          SizedBox(width: 8.w),
          Text(
            "Add Child Profile",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: primaryPurple,
              fontSize: 12.sp,
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
    height: 48.h,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18.r),
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white : color,
        foregroundColor: isOutlined ? color : Colors.white,
        elevation: 0,
        side: isOutlined ? BorderSide(color: color) : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    ),
  );

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text(
          "Sign Out",
          style: TextStyle(fontWeight: FontWeight.w900, color: textDark),
        ),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                  (r) => false,
                );
            },
            child: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.white),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text("Delete $name?"),
        content: Text(
          "Are you sure you want to remove this profile? All progress will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
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
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text("Delete Account?"),
        content: const Text(
          "This will permanently delete your account and all family data. You may need to log in again recently for this to work.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete user data from Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .delete();

                // Delete the user from Firebase Auth
                await currentUser!.delete();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingPage()),
                    (r) => false,
                  );
                }
              } catch (e) {
                // Usually fails if user hasn't logged in recently (Security requirement)
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
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
