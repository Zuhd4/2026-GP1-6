import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_wrapper.dart';

class ProfileSelectionPage extends StatelessWidget {
  const ProfileSelectionPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);

  // --- SQUARE-ROUNDED SMART AVATAR LOADER ---
  Widget _avatarWidget(String? path, {double size = 95}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;
    Widget imageContent;
    if (src.startsWith('http')) {
      imageContent = Image.network(
        src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/lexiaAv.png', fit: BoxFit.cover),
      );
    } else if (src.endsWith('.svg')) {
      imageContent = SvgPicture.asset(
        src,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      imageContent = Image.asset(
        src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/lexiaAv.png', fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: imageContent,
      ),
    );
  }

  // --- PARENT PIN DIALOG ---
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
                        // Compare input PIN with the one from Firestore
                        if (_pinController.text == correctPin) {
                          Navigator.pop(context); // Close dialog
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainWrapper(isChildMode: false),
                            ), // PARENT MODE
                            (route) => false,
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
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        final List<DocumentSnapshot> children =
                            childSnap.hasData ? childSnap.data!.docs : [];

                        return Padding(
                          padding: EdgeInsets.only(bottom: 60.h),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Who's learning today?",
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 35.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40.w),
                                child: Wrap(
                                  spacing: 25.w,
                                  runSpacing: 25.h,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    // 1. Parent Profile
                                    _buildProfileCard(
                                      name: userData['name'] ?? "Parent",
                                      role: "Parent 🔒",
                                      avatarPath: userData['avatarUrl'],
                                      onTap: () => _showPinDialog(
                                        context,
                                        (userData['pin'] ?? "0000").toString(),
                                      ),
                                    ),
                                    // 2. Child Profiles
                                    ...children.map((doc) {
                                      final childData =
                                          doc.data() as Map<String, dynamic>;
                                      return _buildProfileCard(
                                        name: childData['name'] ?? "Child",
                                        role: "child",
                                        avatarPath: childData['avatarUrl'],
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MainWrapper(
                                                  isChildMode: true,
                                                ),
                                          ), // CHILD MODE
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
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
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String role,
    required String? avatarPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 95.r,
            height: 95.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: primaryPurple.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: _avatarWidget(avatarPath, size: 95.r),
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
