import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_helper.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  static const Color primaryBlue = Color(0xFF5B96CA);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  void _showComingSoon(BuildContext context) {
    R.init(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(24)),
        ),
        child: Padding(
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
                  child: Text('🚀', style: TextStyle(fontSize: R.text(28))),
                ),
              ),
              SizedBox(height: R.space(16)),
              Text(
                'Coming Soon!',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(18),
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
              SizedBox(height: R.space(8)),
              Text(
                'This feature will be available soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.black45,
                  fontSize: R.text(12),
                ),
              ),
              SizedBox(height: R.space(24)),
              SizedBox(
                width: double.infinity,
                height: R.buttonH(54),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(R.radius(16)),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  Widget _actionButton(BuildContext context, String text, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.radius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
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
      ),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
          ),
        ),
        child: R.pageWrap(
          child: SingleChildScrollView(
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
                    color: textDark,
                  ),
                ),
                SizedBox(height: R.space(2)),
                Text(
                  'Scan or upload any text image',
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(12),
                    color: Colors.black45,
                  ),
                ),
                SizedBox(height: R.space(28)),

                /// MAIN CARD
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
                      /// HEADER
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
                              decoration: BoxDecoration(
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ACTION BUTTONS ONLY
                      Padding(
                        padding: EdgeInsets.all(R.space(14)),
                        child: Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                context,
                                'Scan',
                                Icons.camera_alt_rounded,
                              ),
                            ),
                            SizedBox(width: R.space(12)),
                            Expanded(
                              child: _actionButton(
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

                SizedBox(height: R.space(40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
