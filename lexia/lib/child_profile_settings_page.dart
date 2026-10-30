import 'auth_identity.dart';
import 'picture_pin_change_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_typography.dart';
import 'widgets/lexia_popup.dart';

// Child settings menu: two matching navigation cards. The original editor
// remains available on its own page, without changing its layout.
class ChildProfileSettingsPage extends StatelessWidget {
  final String childId;
  final String initialName;
  final String initialAvatar;

  const ChildProfileSettingsPage({
    super.key,
    required this.childId,
    required this.initialName,
    required this.initialAvatar,
  });

  static const Color _purple = Color(0xFF6A5ACD);
  static const Color _textDark = Color(0xFF2D3142);

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool useOpenDyslexic,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.getStyle(
            useOpenDyslexic: useOpenDyslexic,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: _textDark.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(
                    icon,
                    color: _purple.withOpacity(0.75),
                    size: 21.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.getStyle(
                      useOpenDyslexic: useOpenDyslexic,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15.r,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthIdentity.parentUid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        final useOpenDyslexic =
            snapshot.data?.data()?['useOpenDyslexicFont'] == true;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFDFB),
                  Color(0xFFFFF9F9),
                  Color(0xFFFFFAF5),
                  Colors.white,
                ],
                stops: [0, 0.4, 0.7, 1],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40.w,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20.r,
                              color: _textDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Profile Settings',
                              style: AppTypography.getStyle(
                                useOpenDyslexic: useOpenDyslexic,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 40.w),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(22.w, 32.h, 22.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            context,
                            title: 'Edit Profile',
                            icon: Icons.person_outline_rounded,
                            useOpenDyslexic: useOpenDyslexic,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildProfileEditPage(
                                  childId: childId,
                                  initialName: initialName,
                                  initialAvatar: initialAvatar,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.h),
                          _sectionCard(
                            context,
                            title: 'Change Picture PIN',
                            icon: Icons.lock_rounded,
                            useOpenDyslexic: useOpenDyslexic,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PicturePinChangePage(childId: childId),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChildProfileEditPage extends StatefulWidget {
  final String childId;
  final String initialName;
  final String initialAvatar;
  final bool openedByParent;

  const ChildProfileEditPage({
    super.key,
    required this.childId,
    required this.initialName,
    required this.initialAvatar,
    this.openedByParent = false,
  });

  @override
  State<ChildProfileEditPage> createState() => _ChildProfileEditPageState();
}

class _ChildProfileEditPageState extends State<ChildProfileEditPage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);

  late TextEditingController _nameController;
  late String _selectedAvatar;

  bool _isSaving = false;

  String? _nameError;

  final List<String> _avatars = [
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
    _nameController = TextEditingController(text: widget.initialName);
    _selectedAvatar = widget.initialAvatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildHeader(BuildContext context, bool useOpenDyslexic) {
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
              "Edit Profile",
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
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

  Widget _avatarWidget(String path, {double size = 50}) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(path, width: size, height: size, fit: BoxFit.cover);
  }

  Future<void> _save(bool useOpenDyslexic) async {
    final name = _nameController.text.trim();

    setState(() {
      _nameError = null;
    });

    if (name.isEmpty) {
      setState(() => _nameError = "Name can't be empty");
      return;
    }

    if (name.length < 2) {
      setState(() => _nameError = "Name is too short");
      return;
    }

    if (name.length > 12) {
      setState(() => _nameError = "Max 12 characters");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = AuthIdentity.parentUid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(widget.childId)
          .update({
            'name': name,
            'avatarUrl': _selectedAvatar,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showSuccessDialog(useOpenDyslexic);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Oops! Something went wrong. Please try again.",
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
                fontSize: 13.sp,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog(bool useOpenDyslexic) {
    LexiaPopup.showMessage(
      context: context,
      title: "Profile Updated!",
      message: "Your changes have been saved successfully.",
      icon: Icons.check_rounded,
      iconColor: green,
      buttonColor: primaryPurple,
      buttonText: "Done",
      barrierDismissible: false,
      useOpenDyslexic: useOpenDyslexic,
      onDone: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _sectionLabel(String label, bool useOpenDyslexic) => Text(
    label,
    style: AppTypography.getStyle(
      useOpenDyslexic: useOpenDyslexic,
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      color: textDark.withOpacity(0.4),
      letterSpacing: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final String uid = AuthIdentity.parentUid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(widget.childId)
          .snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};
        final bool useOpenDyslexic =
            !widget.openedByParent && userData['useOpenDyslexicFont'] == true;

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
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 10.h,
                    ),
                    child: _buildHeader(context, useOpenDyslexic),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 90.r,
                              height: 90.r,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryPurple.withOpacity(0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28.r),
                                child: _avatarWidget(
                                  _selectedAvatar,
                                  size: 90.r,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24.h),

                          _sectionLabel("Name", useOpenDyslexic),
                          SizedBox(height: 8.h),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _nameController,
                              maxLength: 12,
                              style: AppTypography.getStyle(
                                useOpenDyslexic: useOpenDyslexic,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: "Enter child's name",
                                hintStyle: AppTypography.getStyle(
                                  useOpenDyslexic: useOpenDyslexic,
                                  fontSize: 13.sp,
                                  color: Colors.black26,
                                ),
                                counterText: "",
                                errorText: _nameError,
                                errorStyle: AppTypography.getStyle(
                                  useOpenDyslexic: useOpenDyslexic,
                                  fontSize: 10.sp,
                                  color: Colors.redAccent,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: primaryPurple.withOpacity(0.6),
                                  size: 20.r,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide(
                                    color: primaryPurple.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24.h),

                          _sectionLabel("Choose Avatar", useOpenDyslexic),
                          SizedBox(height: 12.h),

                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 12.w,
                                    mainAxisSpacing: 12.h,
                                  ),
                              itemCount: _avatars.length,
                              itemBuilder: (context, index) {
                                final path = _avatars[index];
                                final isSelected = _selectedAvatar == path;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedAvatar = path);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryPurple.withOpacity(0.08)
                                          : const Color(0xFFF8F9FB),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryPurple
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.r),
                                            child: _avatarWidget(
                                              path,
                                              size: 44.r,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 4.r,
                                            right: 4.r,
                                            child: Container(
                                              width: 16.r,
                                              height: 16.r,
                                              decoration: const BoxDecoration(
                                                color: primaryPurple,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 10.r,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 32.h),

                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _save(useOpenDyslexic),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPurple,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: primaryPurple.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                              ),
                              child: _isSaving
                                  ? SizedBox(
                                      height: 20.r,
                                      width: 20.r,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Save Changes",
                                      style: AppTypography.getStyle(
                                        useOpenDyslexic: useOpenDyslexic,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
