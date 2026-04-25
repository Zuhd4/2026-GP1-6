import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EditChildPage extends StatefulWidget {
  final String name;
  final String avatar;

  const EditChildPage({
    super.key,
    required this.name,
    required this.avatar,
  });

  @override
  State<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends State<EditChildPage> {
  late TextEditingController _nameController;
  late String _selectedAvatar;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _selectedAvatar = widget.avatar;
  }

  Widget _avatarWidget(String path) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(path, width: 50.r, height: 50.r);
    }
    return Image.asset(path, width: 50.r, height: 50.r);
  }

  void _save() {
    Navigator.pop(context, {
      "name": _nameController.text.trim(),
      "avatar": _selectedAvatar,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Child"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Child's Name",
                filled: true,
                fillColor: softGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final path = avatars[index];
                final isSelected = _selectedAvatar == path;

                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = path),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryPurple.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? primaryPurple
                            : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(child: _avatarWidget(path)),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                ),
                child: const Text("Save"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}