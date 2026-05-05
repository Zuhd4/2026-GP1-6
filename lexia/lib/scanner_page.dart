import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_helper.dart';
import 'widgets/lexia_popup.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  static const Color primaryGreen = Color(0xFF59A685);
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  void _showComingSoon(BuildContext context) {
    LexiaPopup.showMessage(
      context: context,
      title: 'Coming Soon!',
      message: 'This feature will be available soon!',
      emoji: '🚀',
      buttonColor: primaryGreen.withOpacity(0.8),
      buttonText: 'Got it!',
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(105);

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

        // بدون R.pageWrap هنا
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            topMargin,
            horizontalPad,
            bottomMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Books',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(21),
                  fontWeight: FontWeight.w500,
                  color: textDark.withOpacity(0.9),
                ),
              ),

              SizedBox(height: R.space(2)),

              Text(
                'Scan or upload any text image',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(12),
                  color: Colors.black45,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: R.space(28)),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(R.radius(22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.025),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.space(14),
                        vertical: R.space(24),
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBF8FF), Color(0xFFF5FAFF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(R.radius(22)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: R.icon(62),
                            height: R.icon(62),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.document_scanner_rounded,
                              color: primaryPurple,
                              size: R.icon(30),
                            ),
                          ),
                          SizedBox(width: R.space(14)),
                          Expanded(
                            child: Text(
                              'Scan or upload\nan image',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(18),
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(R.space(14)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _btn(
                              context,
                              'Scan',
                              Icons.camera_alt_rounded,
                            ),
                          ),
                          SizedBox(width: R.space(12)),
                          Expanded(
                            child: _btn(
                              context,
                              'Upload',
                              Icons.file_upload_outlined,
                            ),
                          ),
                        ],
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

  Widget _btn(BuildContext context, String text, IconData icon) {
    return SizedBox(
      height: R.buttonH(54),
      child: ElevatedButton.icon(
        onPressed: () => _showComingSoon(context),
        icon: Icon(icon, size: R.icon(20)),
        label: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: R.text(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(16)),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),
      ),
    );
  }
}
