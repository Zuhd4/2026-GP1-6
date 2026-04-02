import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddChildPopup extends StatefulWidget {
  const AddChildPopup({super.key});

  @override
  State<AddChildPopup> createState() => _AddChildPopupState();
}

class _AddChildPopupState extends State<AddChildPopup> {
  final _nameController = TextEditingController();
  String _selectedAvatar =
      "https://api.dicebear.com/9.x/fun-emoji/png?seed=happy1&backgroundColor=b6e3f4";

  final List<String> avatars = [
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=happy1&backgroundColor=b6e3f4",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child2&backgroundColor=ffd5dc",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child3&backgroundColor=ffdf7f",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child4&backgroundColor=71cf62",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child5&backgroundColor=f7c2f0",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child6&backgroundColor=c0aede",
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
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

            // Name Field
            TextField(
              controller: _nameController,
              onChanged: (val) => setState(() {}),
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

            // Avatar Grid
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pick an Avatar",
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: avatars
                  .map(
                    (url) => GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = url),
                      child: Container(
                        width: 50.r,
                        height: 50.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _selectedAvatar == url
                                ? const Color(0xFF6A5ACD)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9.r),
                          child: Image.network(url),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: 24.h),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5ACD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) return;
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('children')
                      .add({
                        'name': _nameController.text,
                        'avatarUrl': _selectedAvatar,
                        'level': 1, // Default starting level
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  Navigator.pop(context);
                },
                child: Text(
                  "Create Account",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black38, fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
