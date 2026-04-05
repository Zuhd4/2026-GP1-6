import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_screen.dart';
import 'onboarding_page.dart';
import 'add_child_popup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color softPurple = Color(0xFFD8BDD9);

  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- DELETE CHILD PROFILE ---
  Future<void> _deleteChild(String childDocId) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('children')
          .doc(childDocId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- DELETE ENTIRE ACCOUNT LOGIC ---
  Future<void> _deleteAccount() async {
    if (currentUser == null) return;
    try {
      // 1. Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .delete();

      // 2. Delete the Auth account credentials
      await currentUser!.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Security: Please re-login to delete account"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
    }
  }

  // --- DIALOGS ---
  void _showDeleteConfirmation(String childName, String childDocId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Delete Profile",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
            color: textDark,
          ),
        ),
        content: Text(
          "Are you sure you want to delete $childName's profile?",
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChild(childDocId);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Delete Account?",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
            color: textDark,
          ),
        ),
        content: Text(
          "All your data and child profiles will be permanently removed. This action cannot be undone.",
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Keep Account",
              style: TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 247, 248),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22.w, 80.h, 22.w, 140.h),
            child: Column(
              children: [
                // --- HEADER ---
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20.r,
                        color: textDark,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "My Profile",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40.w),
                  ],
                ),
                SizedBox(height: 30.h),

                // --- PARENT INFO ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                        userData['avatarUrl'] ??
                            "https://api.dicebear.com/9.x/fun-emoji/png?seed=parent",
                      ),
                    ),
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: const Color(0xFF6A5ACD),
                      child: Icon(Icons.edit, size: 14.r, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  userData['name'] ?? "Parent Name",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                Text(
                  "Parent Account",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30.h),

                // --- INFO CARD ---
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: softPurple.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _infoTile(
                        Icons.email_rounded,
                        "Email",
                        userData['email'] ?? "No email",
                      ),
                      const Divider(color: Color(0xFFF3F4F8)),
                      _infoTile(
                        Icons.shield_rounded,
                        "PIN Protection",
                        "Enabled",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),

                // --- CHILD SECTION ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Child Account",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('children')
                      .snapshots(),
                  builder: (context, childSnap) {
                    if (!childSnap.hasData || childSnap.data!.docs.isEmpty)
                      return _addChildButton();
                    final childDoc = childSnap.data!.docs.first;
                    final childData = childDoc.data() as Map<String, dynamic>;
                    return _childCard(
                      childData['name'],
                      childData['avatarUrl'],
                      childDoc.id,
                    );
                  },
                ),

                SizedBox(height: 60.h),

                // --- DELETE ACCOUNT BUTTON (SOLID RED) ---
                ElevatedButton.icon(
                  onPressed: _showDeleteAccountConfirmation,
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Delete Account",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                ),

                SizedBox(height: 12.h),

                // --- SIGN OUT BUTTON (WHITE WITH RED BORDER) ---
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFD32F2F),
                  ),
                  label: Text(
                    "Sign Out",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD32F2F),
                    minimumSize: Size(double.infinity, 50.h),
                    side: const BorderSide(
                      color: Color(0xFFD32F2F),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF6A5ACD), size: 20.r),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.black45,
          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _childCard(String name, String avatar, String id) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: softPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              avatar,
              width: 50.r,
              height: 50.r,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                Text(
                  "Child Profile",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDeleteConfirmation(name, id),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addChildButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => const AddChildPopup(),
      ),
      icon: const Icon(Icons.add_circle_rounded),
      label: Text(
        "Add Child Profile",
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6A5ACD),
        minimumSize: Size(double.infinity, 55.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: softPurple.withOpacity(0.3)),
        ),
        elevation: 0,
      ),
    );
  }
}
