import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddChildPopup extends StatefulWidget {
  const AddChildPopup({super.key});

  @override
  State<AddChildPopup> createState() => _AddChildPopupState();
}

class _AddChildPopupState extends State<AddChildPopup> {
  final _nameController = TextEditingController();

  // FIXED: Initial default choice matches your file structure
  String _selectedAvatar = 'assets/lexiaAv.png';

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

  Widget _avatarWidget(String path) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(path, width: 50.r, height: 50.r);
    }
    return Image.asset(path, width: 50.r, height: 50.r, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "New Child Profile",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2D3142),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Child's Name",
                filled: true,
                fillColor: const Color(0xFFF3F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final path = avatars[index];
                  final bool isSelected = _selectedAvatar == path;

                  return GestureDetector(
                    onTap: () {
                      // FIXED: This setState ensures the app remembers which one you clicked
                      setState(() {
                        _selectedAvatar = path;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6A5ACD)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9.r),
                        child: _avatarWidget(path),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD),
                minimumSize: Size(double.infinity, 48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) return;
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // The selected avatar path is now correctly stored in _selectedAvatar
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
              },
              child: const Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
