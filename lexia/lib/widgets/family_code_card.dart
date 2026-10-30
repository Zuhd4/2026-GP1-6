import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lexia_popup.dart';

/// The parent's Family Code controls. The Cloud Function is the authority
/// for code generation and the five-minute reset cooldown.
class FamilyCodeCard extends StatefulWidget {
  const FamilyCodeCard({super.key});

  @override
  State<FamilyCodeCard> createState() => _FamilyCodeCardState();
}

class _FamilyCodeCardState extends State<FamilyCodeCard> {
  static const Color purple = Color(0xFF6A5ACD);
  static const Color ink = Color(0xFF2D3142);
  String? _code;
  String? _error;
  bool _busy = false;
  DateTime? _resetAvailableAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _remainingSeconds > 0) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _remainingSeconds {
    final until = _resetAvailableAt;
    if (until == null) return 0;
    final ms = until.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  String get _remainingLabel {
    final remaining = _remainingSeconds;
    return '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _loadCode({bool reset = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('manageFamilyCode')
          .call(<String, dynamic>{'action': reset ? 'reset' : 'get'});
      final response = await callable.timeout(const Duration(seconds: 15));
      final data = Map<String, dynamic>.from(response.data as Map);
      final code = data['familyCode'] as String?;
      if (code == null || code.isEmpty) {
        throw StateError('Family Code was not returned');
      }
      final seconds = (data['retryAfterSeconds'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _code = code;
        _resetAvailableAt = DateTime.now().add(Duration(seconds: seconds));
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final details = e.details;
      int seconds = 0;
      if (details is Map && details['retryAfterSeconds'] is num) {
        seconds = (details['retryAfterSeconds'] as num).toInt();
      }
      setState(() {
        if (seconds > 0) {
          _resetAvailableAt = DateTime.now().add(Duration(seconds: seconds));
        }
        _error =
            e.message ??
            'Family Code service is unavailable. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Unable to load the Family Code. The Cloud Function may not be deployed yet.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    if (_busy || _code == null || _remainingSeconds > 0) return;
    final confirmed = await LexiaPopup.showConfirm(
      context: context,
      title: 'Reset Family Code?',
      message:
          'The old code will stop working. You can reset the new code again after 5 minutes.',
      confirmText: 'Reset',
      cancelText: 'Cancel',
      confirmColor: purple,
      icon: Icons.refresh_rounded,
      iconColor: purple,
    );
    if (!mounted) return;
    if (confirmed) await _loadCode(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: purple.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded, color: purple, size: 22.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Family Code',
                  style: GoogleFonts.montserrat(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Use this code to connect your children to their Lexia profiles.',
            style: GoogleFonts.montserrat(
              color: ink.withValues(alpha: 0.65),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3FF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: _busy && _code == null
                ? const Center(child: CircularProgressIndicator(color: purple))
                : SelectableText(
                    _code ?? '—',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
          if (_error != null) ...[
            SizedBox(height: 10.h),
            Text(
              _error!,
              style: GoogleFonts.montserrat(
                color: Colors.red.shade700,
                fontSize: 11.sp,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              OutlinedButton.icon(
                onPressed: _code == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: _code!));
                        if (context.mounted) {
                          await LexiaPopup.showMessage(
                            context: context,
                            title: 'Family Code Copied!',
                            message:
                                'Your Family Code has been copied to the clipboard.',
                            icon: Icons.check_rounded,
                            iconColor: const Color(0xFF59A685),
                            buttonColor: const Color(0xFF6A5ACD),
                            buttonText: 'Got it',
                          );
                        }
                      },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _code == null || _remainingSeconds > 0
                    ? null
                    : _confirmReset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset'),
              ),
              if (_code == null)
                TextButton(
                  onPressed: _busy ? null : () => _loadCode(),
                  child: const Text('Retry'),
                ),
            ],
          ),
          if (_remainingSeconds > 0) ...[
            SizedBox(height: 7.h),
            Text(
              'Reset available in $_remainingLabel',
              style: GoogleFonts.montserrat(color: purple, fontSize: 11.sp),
            ),
          ],
        ],
      ),
    );
  }
}
