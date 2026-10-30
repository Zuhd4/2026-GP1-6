import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_identity.dart';
import 'app_typography.dart';

import 'widgets/lexia_popup.dart';

class PicturePinChangePage extends StatefulWidget {
  final String childId;

  const PicturePinChangePage({super.key, required this.childId});

  @override
  State<PicturePinChangePage> createState() => _PicturePinChangePageState();
}

class _PicturePinChangePageState extends State<PicturePinChangePage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
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

  // 0 = current PIN, 1 = new PIN, 2 = confirm new PIN.
  int _step = 0;
  final List<int> _oldPin = [];
  final List<int> _newPin = [];
  final List<int> _confirmPin = [];
  String? _pinError;
  bool _isSaving = false;
  bool _useOpenDyslexic = false;

  List<int> get _activePin => switch (_step) {
    0 => _oldPin,
    1 => _newPin,
    _ => _confirmPin,
  };

  String get _heading => switch (_step) {
    0 => 'Current Picture PIN',
    1 => 'New Picture PIN',
    _ => 'Confirm Picture PIN',
  };

  String get _instructions => switch (_step) {
    0 => 'Choose your current 3 pictures in order.',
    1 => 'Choose 3 new pictures in order.',
    _ => 'Choose those 3 pictures again.',
  };

  void _choosePinImage(int number) {
    if (_isSaving || _activePin.length >= pinLength) return;
    setState(() {
      _activePin.add(number);
      _pinError = null;
    });
  }

  void _back() {
    if (_isSaving) return;
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _step--;
        _pinError = null;
        if (_step == 1) _confirmPin.clear();
      });
    }
  }

  Future<void> _next() async {
    if (_activePin.length != pinLength) {
      setState(() => _pinError = 'Choose all 3 pictures first.');
      return;
    }
    if (_step == 0) {
      await _verifyCurrentPin();
    } else if (_step == 1) {
      setState(() {
        _step = 2;
        _confirmPin.clear();
        _pinError = null;
      });
    } else {
      if (!_pinsMatch()) {
        setState(() {
          _confirmPin.clear();
          _pinError = 'PINs do not match. Please try again.';
        });
      } else {
        _savePin();
      }
    }
  }

  Future<void> _verifyCurrentPin() async {
    if (_isSaving || _oldPin.length != pinLength) return;
    setState(() {
      _isSaving = true;
      _pinError = null;
    });
    try {
      final response =
          await FirebaseFunctions.instanceFor(
            region: 'me-central1',
          ).httpsCallable('manageChildPin').call<Map<String, dynamic>>({
            'action': 'verify',
            'childId': widget.childId,
            'oldPin': List<int>.from(_oldPin),
          });
      if (response.data['success'] != true) {
        throw StateError('Current Picture PIN was not verified.');
      }
      if (!mounted) return;
      setState(() {
        _step = 1;
        _newPin.clear();
        _confirmPin.clear();
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final isWrongPin = e.code == 'permission-denied';
      setState(() {
        _oldPin.clear();
        _pinError = isWrongPin
            ? null
            : (e.message ?? 'Could not verify your current Picture PIN.');
      });
      if (isWrongPin) {
        await LexiaPopup.showMessage(
          context: context,
          title: 'Incorrect Picture PIN',
          message: 'Those pictures do not match. Please try again.',
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.redAccent,
          buttonColor: primaryPurple,
          buttonText: 'Try Again',
          useOpenDyslexic: _useOpenDyslexic,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _pinError = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _pinsMatch() {
    if (_newPin.length != pinLength || _confirmPin.length != pinLength) {
      return false;
    }
    for (int i = 0; i < pinLength; i++) {
      if (_newPin[i] != _confirmPin[i]) return false;
    }
    return true;
  }

  Future<void> _savePin() async {
    if (_isSaving || _oldPin.length != 3 || !_pinsMatch()) return;
    setState(() {
      _isSaving = true;
      _pinError = null;
    });
    try {
      final response =
          await FirebaseFunctions.instanceFor(
            region: 'me-central1',
          ).httpsCallable('manageChildPin').call<Map<String, dynamic>>({
            'action': 'change',
            'childId': widget.childId,
            'oldPin': List<int>.from(_oldPin),
            'newPin': List<int>.from(_newPin),
          });
      if (response.data['success'] != true) {
        throw StateError('Firebase did not confirm that the PIN was saved.');
      }
      if (!mounted) return;
      await LexiaPopup.showMessage(
        context: context,
        title: 'Picture PIN updated',
        message: 'Your new picture sequence has been saved.',
        icon: Icons.check_rounded,
        iconColor: const Color(0xFF59A685),
        useOpenDyslexic: _useOpenDyslexic,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _pinError = e.message ?? 'Could not change Picture PIN.';
        // The backend verifies the current PIN during the change action.
        // Return to that step so the child can correct it.
        _step = 0;
        _oldPin.clear();
        _newPin.clear();
        _confirmPin.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _pinError = 'PIN was not saved. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _pinImage(int number) {
    return Image.asset(
      'assets/pin_photos/pin_$number.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(pinFallbackIcons[number - 1], size: 30.r, color: primaryPurple),
    );
  }

  // Matches AddChildPage._picturePinSection (same slot sizes, card,
  // spacing, picture grid, selected counter, Undo, and Clear actions).
  Widget _picturePinSection() {
    final active = _activePin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _instructions,
          style: AppTypography.getStyle(
            useOpenDyslexic: _useOpenDyslexic,
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
                              style: AppTypography.getStyle(
                                useOpenDyslexic: _useOpenDyslexic,
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
                      clipBehavior: Clip.antiAlias,
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
                    style: AppTypography.getStyle(
                      useOpenDyslexic: _useOpenDyslexic,
                      color: primaryPurple,
                      fontSize: 12.sp,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSaving || active.isEmpty
                        ? null
                        : () => setState(() {
                            active.removeLast();
                            _pinError = null;
                          }),
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Undo'),
                  ),
                  TextButton(
                    onPressed: _isSaving || active.isEmpty
                        ? null
                        : () => setState(() {
                            active.clear();
                            _pinError = null;
                          }),
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
              style: AppTypography.getStyle(
                useOpenDyslexic: _useOpenDyslexic,
                fontSize: 12.sp,
                color: Colors.redAccent,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final childRef = FirebaseFirestore.instance
        .collection('users')
        .doc(AuthIdentity.parentUid)
        .collection('children')
        .doc(widget.childId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: childRef.snapshots(),
      builder: (context, snapshot) {
        _useOpenDyslexic =
            snapshot.data?.data()?['useOpenDyslexicFont'] == true;
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
                  Row(
                    children: [
                      SizedBox(
                        width: 40.w,
                        child: IconButton(
                          onPressed: _back,
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
                            _step == 0
                                ? 'Change Picture PIN'
                                : (_step == 1
                                      ? 'New Picture PIN'
                                      : 'Confirm PIN'),
                            style: AppTypography.getStyle(
                              useOpenDyslexic: _useOpenDyslexic,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                              color: textDark,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Text(
                            _heading,
                            style: AppTypography.getStyle(
                              useOpenDyslexic: _useOpenDyslexic,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          _picturePinSection(),
                          SizedBox(height: 32.h),
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _next,
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
                                      _step == 2 ? 'Save Picture PIN' : 'Next',
                                      style: AppTypography.getStyle(
                                        useOpenDyslexic: _useOpenDyslexic,
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
