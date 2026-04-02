import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'main_wrapper.dart';
import 'child_home_page.dart';

class ProfileSelectionPage extends StatelessWidget {
  const ProfileSelectionPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);

  // --- PIN DIALOG ---
  void _showPinDialog(BuildContext context, String correctPin) {
    final TextEditingController _pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter PIN",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Enter your 4-digit PIN to access parent controls",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8.w,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF3F4F8),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black38,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_pinController.text == correctPin) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainWrapper(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Incorrect PIN"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Enter",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 247, 248),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Logo (Reduced padding to move content up)
            Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Image.asset('assets/Lexia.png', width: 75.w),
            ),

            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final userData =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('children')
                        .snapshots(),
                    builder: (context, childSnap) {
                      return Padding(
                        // Pushing the whole group upward
                        padding: EdgeInsets.only(bottom: 60.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Who's learning today?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Select a profile to continue",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.black38,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 35.h),

                            // Horizontal Layout for Profiles
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildProfileCard(
                                  name: userData['name'] ?? "Parent",
                                  role: "Parent 🔒",
                                  imageUrl:
                                      userData['avatarUrl'] ??
                                      "https://api.dicebear.com/9.x/fun-emoji/png?seed=parent",
                                  onTap: () => _showPinDialog(
                                    context,
                                    (userData['pin'] ?? "0000").toString(),
                                  ),
                                ),
                                if (childSnap.hasData &&
                                    childSnap.data!.docs.isNotEmpty) ...[
                                  SizedBox(width: 16.w),
                                  Builder(
                                    builder: (context) {
                                      final childData =
                                          childSnap.data!.docs.first.data()
                                              as Map<String, dynamic>;
                                      return _buildProfileCard(
                                        name: childData['name'] ?? "Child",
                                        role: "child",
                                        imageUrl:
                                            childData['avatarUrl'] ??
                                            "https://api.dicebear.com/9.x/fun-emoji/png?seed=child",
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ChildHomePage(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String role,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Square Profile Image
          Container(
            width: 95.r, // Slightly smaller for a tighter look
            height: 95.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: primaryPurple.withOpacity(0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
          SizedBox(height: 4.h),
          // Role Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: role.contains('🔒')
                  ? Colors.black.withOpacity(0.05)
                  : primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: role.contains('🔒') ? Colors.black45 : primaryPurple,
                fontSize: 8.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
