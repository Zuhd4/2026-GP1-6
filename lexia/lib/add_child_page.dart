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
  final _nameController = TextEditingController();
  String _selectedAvatar = 'assets/lexiaAv.png';

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color softGrey = Color(0xFFF8F9FB);

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

  Widget _avatarWidget(String path) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(path, width: 50.r, height: 50.r);
    }
    return Image.asset(path, width: 50.r, height: 50.r);
  }

  Future<void> _createChild() async {
    if (_nameController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .add({
            'name': _nameController.text.trim(),
            'avatarUrl': _selectedAvatar,
            'level': 1,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "New Child Profile",
          style: GoogleFonts.montserrat(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18.r, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    "Choose an avatar and enter a name",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.sp,
                      color: Colors.black38,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.montserrat(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Child's Name",
                      filled: true,
                      fillColor: softGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16.w),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // GRID (SCROLLABLE)
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final path = avatars[index];
                  final bool isSelected = _selectedAvatar == path;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = path),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryPurple.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? primaryPurple
                              : Colors.black.withOpacity(0.05),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(child: _avatarWidget(path)),
                    ),
                  );
                },
              ),
            ),

            // BUTTON (STAYS VISIBLE ABOVE KEYBOARD)
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 20.h),
              child: SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: _createChild,
                  child: Text(
                    "Create Account",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
