import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({super.key});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final TextEditingController _nameController = TextEditingController();

  String _selectedAvatar = 'assets/lexiaAv.png';
  String? _nameError;
  bool _isSaving = false;
  int _step = 0; // 0: details, 1: create PIN, 2: confirm PIN

  final List<int> _picturePin = [];
  final List<int> _confirmPin = [];
  String? _pinError;

  static const int pinLength = 3;
  static const List<IconData> pinFallbackIcons = [
    Icons.pets_rounded,
    Icons.local_florist_rounded,
    Icons.star_rounded,
    Icons.sports_soccer_rounded,
    Icons.icecream_rounded,
    Icons.flight_rounded,
    Icons.favorite_rounded,
    Icons.directions_car_rounded,
    Icons.cake_rounded,
  ];

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

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

  Widget _avatarWidget(String path, {double size = 50}) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }

  void _choosePinImage(int number) {
    final active = _step == 2 ? _confirmPin : _picturePin;
    if (_isSaving || active.length >= pinLength) return;
    setState(() {
      active.add(number);
      _pinError = null;
    });
  }

  void _goToPinStep() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Please enter your child's name");
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _nameError = null;
      _step = 1;
    });
  }

  void _advancePin() {
    if (_picturePin.length != pinLength) {
      setState(() => _pinError = 'Choose all 3 pictures first.');
      return;
    }
    setState(() {
      _confirmPin.clear();
      _pinError = null;
      _step = 2;
    });
  }

  void _confirmPinAndSave() {
    if (_confirmPin.length != pinLength) {
      setState(() => _pinError = 'Select all 3 pictures again.');
      return;
    }
    if (!_pinsMatch()) {
      setState(() {
        _confirmPin.clear();
        _pinError = 'PINs do not match. Please try again.';
      });
      return;
    }
    _createChild();
  }

  bool _pinsMatch() {
    if (_picturePin.length != pinLength || _confirmPin.length != pinLength)
      return false;
    for (int i = 0; i < pinLength; i++) {
      if (_picturePin[i] != _confirmPin[i]) return false;
    }
    return true;
  }

  Widget _pinImage(int number) {
    // Replace placeholders once assets/pin_photos/pin_1.png through
    // pin_9.png have been added to the project.
    return Image.asset(
      'assets/pin_photos/pin_$number.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(pinFallbackIcons[number - 1], size: 30.r, color: primaryPurple),
    );
  }

  Widget _picturePinSection() {
    final active = _step == 2 ? _confirmPin : _picturePin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(_step == 2 ? 'Confirm Picture PIN' : 'Child Picture PIN'),
        SizedBox(height: 7.h),
        Text(
          _step == 2
              ? 'Select the same 3 pictures again in the same order.'
              : 'Select 3 pictures in order. Your child will use the same '
                    'sequence to log in.',
          style: GoogleFonts.montserrat(
            fontSize: 12.sp,
            color: textDark.withValues(alpha: 0.65),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (index) {
                  final filled = index < active.length;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    width: 50.r,
                    height: 50.r,
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFFF2EDFF)
                          : const Color(0xFFF8F9FB),
                      border: Border.all(
                        color: filled ? primaryPurple : const Color(0xFFE3DDF6),
                      ),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: filled
                        ? _pinImage(active[index])
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14.sp,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                  );
                }),
              ),
              SizedBox(height: 14.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 1.1,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final number = index + 1;
                  return InkWell(
                    onTap: _isSaving || active.length >= pinLength
                        ? null
                        : () => _choosePinImage(number),
                    borderRadius: BorderRadius.circular(15.r),
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6FF),
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: const Color(0xFFE3DDF6)),
                      ),
                      child: _pinImage(number),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${active.length}/3 selected',
                    style: GoogleFonts.montserrat(
                      color: primaryPurple,
                      fontSize: 12.sp,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSaving || active.isEmpty
                        ? null
                        : () {
                            setState(() {
                              active.removeLast();
                              _pinError = null;
                            });
                          },
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Undo'),
                  ),
                  TextButton(
                    onPressed: _isSaving || active.isEmpty
                        ? null
                        : () {
                            setState(() {
                              active.clear();
                              _pinError = null;
                            });
                          },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_pinError != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              _pinError!,
              style: GoogleFonts.montserrat(
                fontSize: 12.sp,
                color: Colors.redAccent,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _createChild() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty || !_pinsMatch()) {
      setState(() {
        _nameError = name.isEmpty ? "Please enter your child's name" : null;
        _pinError = !_pinsMatch() ? 'Confirm the same 3 pictures first.' : null;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parent sign-in required.')));
      return;
    }

    setState(() {
      _nameError = null;
      _pinError = null;
      _isSaving = true;
    });

    final childRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('children')
        .doc();
    bool created = false;
    try {
      // The Cloud Function sets the PIN on an existing child document.
      await childRef.set({
        'name': name,
        'avatarUrl': _selectedAvatar,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
      created = true;

      await FirebaseFunctions.instanceFor(
        region: 'me-central1',
      ).httpsCallable('manageChildPin').call({
        'action': 'set',
        'childId': childRef.id,
        'newPin': List<int>.from(_picturePin),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (created) {
        // Best-effort rollback, to avoid a child without a PIN.
        try {
          await childRef.delete();
        } catch (_) {
          // A failed cleanup must be handled by an administrator.
          // Do not claim that the profile was rolled back.
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FirebaseFunctionsException
                  ? 'Could not set picture PIN: ${e.message ?? e.code}'
                  : 'Could not create child profile. Check Firebase connection.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _header(BuildContext context) {
    return _buildHeader(
      context,
      _step == 0
          ? "New Child Profile"
          : (_step == 1 ? "Picture PIN" : "Confirm PIN"),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      children: [
        SizedBox(
          width: 40.w,
          child: IconButton(
            onPressed: () {
              if (_isSaving) return;
              if (_step > 0) {
                setState(() {
                  _step--;
                  _pinError = null;
                  if (_step == 1) _confirmPin.clear();
                });
              } else {
                Navigator.pop(context);
              }
            },
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
              title,
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

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: textDark.withOpacity(0.4),
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
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
              _header(context),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 32.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_step == 0) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Column(
                            children: [
                              Container(
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
                              SizedBox(height: 14.h),
                              Text(
                                "Create a child profile",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Choose an avatar and enter your child's name.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.sp,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 22.h),

                        _sectionLabel("Name"),
                        SizedBox(height: 8.h),

                        TextField(
                          controller: _nameController,
                          onChanged: (value) {
                            if (_nameError != null && value.trim().isNotEmpty) {
                              setState(() => _nameError = null);
                            }
                          },
                          style: GoogleFonts.montserrat(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: "Child's Name",
                            hintStyle: GoogleFonts.montserrat(
                              fontSize: 13.sp,
                              color: Colors.black26,
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
                            errorText: _nameError,
                            errorStyle: GoogleFonts.montserrat(
                              fontSize: 11.sp,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
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

                        SizedBox(height: 24.h),

                        _sectionLabel("Choose Avatar"),
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
                            itemCount: avatars.length,
                            itemBuilder: (context, index) {
                              final path = avatars[index];
                              final bool isSelected = _selectedAvatar == path;

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
                      ],
                      if (_step >= 1) ...[
                        SizedBox(height: 10.h),
                        Text(
                          _step == 2
                              ? "Confirm your Picture PIN"
                              : "Create a Picture PIN",
                          style: GoogleFonts.montserrat(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _picturePinSection(),
                      ],
                      SizedBox(height: 32.h),

                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : (_step == 0
                                    ? _goToPinStep
                                    : (_step == 1
                                          ? _advancePin
                                          : _confirmPinAndSave)),
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
                                  _step == 2 ? "Create Account" : "Next",
                                  style: GoogleFonts.montserrat(
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
  }
}
