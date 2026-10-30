import 'package:cloud_functions/cloud_functions.dart';
import 'auth_identity.dart';
import 'profile_selection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_helper.dart';

/// Child Family Code UI connected to the deployed verification function.
class ChildFamilyCodePage extends StatefulWidget {
  const ChildFamilyCodePage({super.key});

  @override
  State<ChildFamilyCodePage> createState() => _ChildFamilyCodePageState();
}

class _ChildFamilyCodePageState extends State<ChildFamilyCodePage> {
  final TextEditingController _codeController = TextEditingController();

  static const Color primary = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);
  static const Color softBlue = Color(0xFFEFF7FF);
  static const Color softPink = Color(0xFFFFF5F8);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  String? _codeError;
  Future<void> _continue() async {
    if (_isLoading) return;
    final code = _codeController.text.toUpperCase().replaceAll(
      RegExp(r'[\s-]'),
      '',
    );
    if (code.isEmpty) {
      setState(() => _codeError = 'Field required');
      return;
    }
    if (code.length != 16) {
      setState(() => _codeError = 'Enter your 16-character Family Code.');
      return;
    }
    setState(() {
      _codeError = null;
      _isLoading = true;
    });
    try {
      final response =
          await FirebaseFunctions.instanceFor(region: 'me-central1')
              .httpsCallable('verifyFamilyCode')
              .call<Map<String, dynamic>>({'familyCode': code});
      final profiles = (response.data['profiles'] as List<dynamic>? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      AuthIdentity.familyCode = code;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileSelectionPage(familyCode: code, profiles: profiles),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(
        () => _codeError = e.message ?? 'Family Code verification failed.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _codeError = 'Could not connect. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [softBlue, softPink, Color(0xFFFFFCFF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              R.pagePad,
              R.space(40),
              R.pagePad,
              R.space(25),
            ),
            children: [
              Center(
                child: Image.asset(
                  'assets/Lexia.png',
                  width: R.s(160),
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: R.space(37)),
              Container(
                padding: EdgeInsets.all(R.space(18)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(R.radius(28)),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.055),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to login options',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Child Login',
                            style: GoogleFonts.montserrat(
                              fontSize: R.text(18),
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: R.space(5)),
                    Text(
                      'Ask your parent for your Family Code.',
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(11),
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: R.space(23)),
                    TextField(
                      controller: _codeController,
                      onChanged: (_) {
                        if (_codeError != null) {
                          setState(() => _codeError = null);
                        }
                      },
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      maxLength: 19,
                      style: GoogleFonts.montserrat(fontSize: R.text(11)),
                      decoration: InputDecoration(
                        labelText: 'Enter your Family Code',
                        errorText: _codeError,
                        errorStyle: GoogleFonts.montserrat(
                          color: Colors.red,
                          fontSize: R.text(10),
                          fontWeight: FontWeight.w500,
                        ),
                        counterText: '',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: R.text(11),
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.key_rounded,
                          color: primary,
                          size: R.icon(17),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(18)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(18)),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.035),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(R.radius(18)),
                          borderSide: const BorderSide(
                            color: primary,
                            width: 1.15,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: R.space(13),
                          horizontal: R.space(12),
                        ),
                      ),
                      onSubmitted: (_) => _continue(),
                    ),
                    SizedBox(height: R.space(23)),
                    SizedBox(
                      width: double.infinity,
                      height: R.buttonH(47),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(R.radius(18)),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: R.text(12),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
