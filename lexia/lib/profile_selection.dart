import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_identity.dart';
import 'main_wrapper.dart';
import 'onboarding_page.dart';
import 'responsive_helper.dart';

class ProfileSelectionPage extends StatefulWidget {
  final String? familyCode;
  final List<Map<String, dynamic>> profiles;
  const ProfileSelectionPage({
    super.key,
    this.familyCode,
    this.profiles = const [],
  });
  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage>
    with WidgetsBindingObserver {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  bool loading = false;
  String? error;
  String? selected;
  final List<int> pin = [];
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showParentPassword = false;
  bool _pinDialogOpen = false;

  // Backend returns retryAfterSeconds; never guess the lockout duration.
  final Map<String, DateTime> _pinLockedUntil = {};
  final ValueNotifier<int> _countdownTick = ValueNotifier<int>(0);
  Timer? _lockTimer;
  // Keep each child's server-reported lockout across navigation and app restarts.
  static const FlutterSecureStorage _pinLockStorage = FlutterSecureStorage();
  String _pinLockKey(String childId) =>
      'lexia_picture_pin_locked_until_$childId';

  Future<void> _restorePinLock(String childId) async {
    try {
      final stored = await _pinLockStorage.read(key: _pinLockKey(childId));
      final timestamp = int.tryParse(stored ?? '');
      if (timestamp == null) return;
      final until = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (!until.isAfter(DateTime.now())) {
        await _pinLockStorage.delete(key: _pinLockKey(childId));
        return;
      }
      if (!mounted) return;
      // Never shorten a newer lockout already recorded in this instance.
      final existing = _pinLockedUntil[childId];
      if (existing == null || until.isAfter(existing)) {
        _pinLockedUntil[childId] = until;
      }
      _startLockTimer();
      _countdownTick.value++;
    } catch (error) {
      debugPrint('Could not restore Picture PIN lockout: $error');
    }
  }

  void _startLockTimer() {
    if (_lockTimer != null) return;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _lockTimer = null;
        return;
      }
      _pinLockedUntil.removeWhere(
        (id, until) => !until.isAfter(DateTime.now()),
      );
      _countdownTick.value++;
      if (_pinLockedUntil.isEmpty) {
        timer.cancel();
        _lockTimer = null;
      }
    });
  }

  int _remainingPinSeconds(String childId) {
    final until = _pinLockedUntil[childId];
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inMilliseconds;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  String _pinCountdown(String childId) {
    final seconds = _remainingPinSeconds(childId);
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  Future<void> _setPinLock(String childId, int seconds) async {
    if (seconds <= 0) return;
    final until = DateTime.now().add(Duration(seconds: seconds));
    _pinLockedUntil[childId] = until;
    _countdownTick.value++;
    _startLockTimer();
    try {
      await _pinLockStorage.write(
        key: _pinLockKey(childId),
        value: until.millisecondsSinceEpoch.toString(),
      );
    } catch (error) {
      debugPrint('Could not persist Picture PIN lockout: $error');
    }
  }

  int _retryAfterSeconds(FirebaseFunctionsException exception) {
    final details = exception.details;
    if (details is Map) {
      final value = details['retryAfterSeconds'];
      if (value is num) return value.ceil();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final profile in widget.profiles) {
      final id = (profile['childId'] ?? '').toString();
      if (id.isNotEmpty) _restorePinLock(id);
    }
    final code = widget.familyCode;
    if (code != null && code.isNotEmpty) {
      AuthIdentity.rememberFamilyCode(
        code,
      ).then((_) => AuthIdentity.rememberProfiles(widget.profiles));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    _countdownTick.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) &&
        _pinDialogOpen &&
        mounted) {
      // Returning to the app always starts from profile selection, not
      // an unfinished PIN entry. The family code remains remembered.
      _pinDialogOpen = false;
      pin.clear();
      error = null;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _protectedLogout() async {
    final code = widget.familyCode ?? AuthIdentity.familyCode;
    if (code == null) return;
    _email.clear();
    _password.clear();
    _showParentPassword = false;
    String? approvalError;
    String? emailRequiredError;
    String? passwordRequiredError;
    bool approving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) {
          return MediaQuery(
            data: MediaQuery.of(
              dialogContext,
            ).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(
                horizontal: R.space(28),
                vertical: R.space(24),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.radius(24)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: R.maxContentWidth < 340 ? R.maxContentWidth : 340,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(R.space(22)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: R.icon(60),
                        height: R.icon(60),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF9E6),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.family_restroom_rounded,
                            color: primaryPurple,
                            size: R.icon(30),
                          ),
                        ),
                      ),
                      SizedBox(height: R.space(16)),
                      Text(
                        'Parent approval',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: R.text(17),
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: R.space(8)),
                      Text(
                        'Enter your parent account details to log out.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: R.text(12),
                          color: Colors.black45,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: R.space(18)),
                      TextField(
                        controller: _email,
                        onChanged: (_) {
                          if (emailRequiredError != null) {
                            refresh(() => emailRequiredError = null);
                          }
                        },
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: GoogleFonts.montserrat(fontSize: R.text(13)),
                        decoration: InputDecoration(
                          labelText: 'Parent email',
                          errorText: emailRequiredError,
                          errorStyle: GoogleFonts.montserrat(
                            color: Colors.red,
                            fontSize: R.text(10),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF8F6FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.radius(14)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: R.space(12)),
                      TextField(
                        controller: _password,
                        onChanged: (_) {
                          if (passwordRequiredError != null) {
                            refresh(() => passwordRequiredError = null);
                          }
                        },
                        obscureText: !_showParentPassword,
                        autofillHints: const [AutofillHints.password],
                        style: GoogleFonts.montserrat(fontSize: R.text(13)),
                        decoration: InputDecoration(
                          labelText: 'Parent password',
                          errorText: passwordRequiredError,
                          errorStyle: GoogleFonts.montserrat(
                            color: Colors.red,
                            fontSize: R.text(10),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _showParentPassword
                                ? 'Hide password'
                                : 'Show password',
                            icon: Icon(
                              _showParentPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => refresh(() {
                              _showParentPassword = !_showParentPassword;
                            }),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F6FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.radius(14)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (approvalError != null) ...[
                        SizedBox(height: R.space(12)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            approvalError!,
                            style: GoogleFonts.montserrat(
                              color: Colors.red,
                              fontSize: R.text(10),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: R.space(22)),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: approving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.montserrat(
                                  fontSize: R.text(12),
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: R.space(10)),
                          Expanded(
                            child: SizedBox(
                              height: R.buttonH(46),
                              child: ElevatedButton(
                                onPressed: approving
                                    ? null
                                    : () async {
                                        if (_email.text.trim().isEmpty ||
                                            _password.text.isEmpty) {
                                          refresh(() {
                                            approvalError = null;
                                            emailRequiredError =
                                                _email.text.trim().isEmpty
                                                ? 'Field required'
                                                : null;
                                            passwordRequiredError =
                                                _password.text.isEmpty
                                                ? 'Field required'
                                                : null;
                                          });
                                          return;
                                        }
                                        refresh(() {
                                          approving = true;
                                          approvalError = null;
                                          emailRequiredError = null;
                                          passwordRequiredError = null;
                                        });
                                        try {
                                          await FirebaseAuth.instance
                                              .signInWithEmailAndPassword(
                                                email: _email.text.trim(),
                                                password: _password.text,
                                              );
                                          final response =
                                              await FirebaseFunctions.instanceFor(
                                                    region: 'me-central1',
                                                  )
                                                  .httpsCallable(
                                                    'manageFamilyCode',
                                                  )
                                                  .call<Map<String, dynamic>>({
                                                    'action': 'get',
                                                  });
                                          if (response.data['familyCode'] !=
                                              code) {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            throw StateError(
                                              'Wrong family account',
                                            );
                                          }
                                          await FirebaseAuth.instance.signOut();
                                          AuthIdentity.clearChild();
                                          await AuthIdentity.forgetFamilyCode();
                                          if (!dialogContext.mounted) return;
                                          Navigator.of(dialogContext).pop();
                                          if (!mounted) return;
                                          Navigator.of(
                                            this.context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const OnboardingPage(),
                                            ),
                                            (_) => false,
                                          );
                                        } catch (_) {
                                          if (dialogContext.mounted) {
                                            refresh(
                                              () => approvalError =
                                                  'Invalid email or password',
                                            );
                                          }
                                        } finally {
                                          if (dialogContext.mounted) {
                                            refresh(() => approving = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      R.radius(14),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Log out',
                                  style: GoogleFonts.montserrat(
                                    fontSize: R.text(12),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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
            ),
          );
        },
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(R.radius(24)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.radius(24)),
        child: imageContent,
      ),
    );
  }

  Future<void> _loginChild(String childId) async {
    if (loading || pin.length != 3 || _remainingPinSeconds(childId) > 0) return;
    final code = widget.familyCode ?? AuthIdentity.familyCode;
    if (code == null || code.isEmpty) {
      setState(() => error = 'Enter your Family Code again.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('loginChild')
          .call<Map<String, dynamic>>({
            'familyCode': code,
            'childId': childId,
            'pin': List<int>.from(pin),
          });
      final data = result.data;
      await FirebaseAuth.instance.signInWithCustomToken(
        data['customToken'] as String,
      );
      AuthIdentity.configureChild(data['parentUid'] as String, childId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainWrapper(isChildMode: true, childId: childId),
        ),
        (_) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final retrySeconds = _retryAfterSeconds(e);
      if (retrySeconds > 0) await _setPinLock(childId, retrySeconds);
      setState(() {
        error = retrySeconds > 0 ? null : (e.message ?? 'Incorrect PIN');
        pin.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Unable to sign in. Please try again.';
        pin.clear();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _showPicturePin(String childId) async {
    // Restore lockout *before* drawing the PIN dialog, without attempting a PIN.
    await _restorePinLock(childId);
    if (!mounted) return;
    setState(() {
      selected = childId;
      pin.clear();
      error = null;
    });
    _pinDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => ValueListenableBuilder<int>(
          valueListenable: _countdownTick,
          builder: (context, tick, _) => StatefulBuilder(
            builder: (dialogContext, refresh) => MediaQuery(
              data: MediaQuery.of(
                dialogContext,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: R.space(28),
                  vertical: R.space(24),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(24)),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: R.maxContentWidth < 340 ? R.maxContentWidth : 340,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(R.space(18)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Picture PIN',
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(17),
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: R.space(8)),
                        Text(
                          'Choose your three pictures in order',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(12),
                            color: Colors.black45,
                          ),
                        ),
                        SizedBox(height: R.space(14)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final filled = index < pin.length;
                            return GestureDetector(
                              onTap:
                                  loading ||
                                      _remainingPinSeconds(childId) > 0 ||
                                      !filled
                                  ? null
                                  : () {
                                      pin.removeAt(index);
                                      error = null;
                                      refresh(() {});
                                    },
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: R.space(4),
                                ),
                                height: R.icon(57),
                                width: R.icon(57),
                                padding: EdgeInsets.all(R.space(4)),
                                decoration: BoxDecoration(
                                  color: _remainingPinSeconds(childId) > 0
                                      ? const Color(0xFFE9E9E9)
                                      : filled
                                      ? const Color(0xFFF2EDFF)
                                      : const Color(0xFFF8F9FB),
                                  border: Border.all(
                                    color: _remainingPinSeconds(childId) > 0
                                        ? const Color(0xFFD0D0D0)
                                        : filled
                                        ? primaryPurple
                                        : const Color(0xFFE3DDF6),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    R.radius(13),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(9),
                                  ),
                                  child: _remainingPinSeconds(childId) > 0
                                      ? Center(
                                          child: Icon(
                                            Icons.lock_rounded,
                                            color: const Color(0xFF888888),
                                            size: R.icon(24),
                                          ),
                                        )
                                      : filled
                                      ? Image.asset(
                                          'assets/pin_photos/pin_${pin[index]}.png',
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: R.text(14),
                                              color: Colors.black38,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: R.space(10)),
                        Text(
                          '${pin.length}/3 selected',
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(12),
                            color: primaryPurple,
                          ),
                        ),
                        if (_remainingPinSeconds(childId) > 0) ...[
                          SizedBox(height: R.space(10)),
                          Icon(
                            Icons.lock_clock_rounded,
                            color: Colors.grey,
                            size: R.icon(23),
                          ),
                          SizedBox(height: R.space(4)),
                          Text(
                            'Picture PIN temporarily locked',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: R.text(11),
                              color: Colors.redAccent,
                            ),
                          ),
                          SizedBox(height: R.space(5)),
                          Text(
                            'Try again in ${_pinCountdown(childId)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: R.text(13),
                              fontWeight: FontWeight.w600,
                              color: primaryPurple,
                            ),
                          ),
                        ],
                        if (error != null &&
                            _remainingPinSeconds(childId) == 0) ...[
                          SizedBox(height: R.space(8)),
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: R.text(11),
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                        SizedBox(height: R.space(14)),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: R.space(8),
                                crossAxisSpacing: R.space(8),
                                childAspectRatio: 1,
                              ),
                          itemCount: 9,
                          itemBuilder: (context, i) => InkWell(
                            onTap:
                                loading ||
                                    _remainingPinSeconds(childId) > 0 ||
                                    pin.length >= 3
                                ? null
                                : () async {
                                    pin.add(i + 1);
                                    error = null;
                                    refresh(() {});
                                    if (pin.length == 3) {
                                      await _loginChild(childId);
                                      if (dialogContext.mounted && mounted)
                                        refresh(() {});
                                    }
                                  },
                            borderRadius: BorderRadius.circular(R.radius(14)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(R.radius(14)),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColorFiltered(
                                    colorFilter: ColorFilter.matrix(
                                      _remainingPinSeconds(childId) > 0
                                          ? const [
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0.2126,
                                              0.7152,
                                              0.0722,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                            ]
                                          : const [
                                              1,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                              0,
                                              0,
                                              0,
                                              0,
                                              1,
                                              0,
                                            ],
                                    ),
                                    child: Image.asset(
                                      'assets/pin_photos/pin_${i + 1}.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (_remainingPinSeconds(childId) > 0)
                                    Container(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: R.space(16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: loading || pin.isEmpty
                                  ? null
                                  : () {
                                      pin.removeLast();
                                      error = null;
                                      refresh(() {});
                                    },
                              icon: const Icon(
                                Icons.backspace_outlined,
                                size: 18,
                              ),
                              label: const Text('Undo'),
                            ),
                            TextButton(
                              onPressed: loading || pin.isEmpty
                                  ? null
                                  : () {
                                      pin.clear();
                                      error = null;
                                      refresh(() {});
                                    },
                              child: const Text('Clear'),
                            ),
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                        if (loading)
                          const CircularProgressIndicator(color: primaryPurple),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _pinDialogOpen = false;
      pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
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
                padding: EdgeInsets.only(top: R.space(60)),
                child: Image.asset('assets/Lexia.png', width: R.s(85)),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Text(
                          "Who's learning today?",
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(22),
                            fontWeight: FontWeight.w400,
                            color: textDark.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: R.space(10)),
                        Text(
                          'choose your profile to continue',
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(12),
                            color: Colors.black45,
                          ),
                        ),
                        SizedBox(height: R.space(40)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: R.space(30),
                          ),
                          child: Wrap(
                            spacing: R.space(25),
                            runSpacing: R.space(35),
                            alignment: WrapAlignment.center,
                            children: widget.profiles
                                .map(
                                  (child) => _buildProfileCard(
                                    name: (child['name'] ?? 'Child').toString(),
                                    role: 'Child',
                                    avatarPath: (child['avatarUrl'] ?? '')
                                        .toString(),
                                    onTap: () => _showPicturePin(
                                      (child['childId'] ?? '').toString(),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        SizedBox(height: R.space(40)),
                        TextButton.icon(
                          onPressed: _protectedLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Log out'),
                        ),
                      ],
                    ),
                  ),
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
    final double cardSize = R.s(105);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(R.radius(26)),
              child: _avatarWidget(avatarPath, size: cardSize),
            ),
          ),
          SizedBox(height: R.space(12)),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: R.text(14),
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          SizedBox(height: R.space(5)),
          Text(
            role.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.black54,
              fontSize: R.text(9),
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
