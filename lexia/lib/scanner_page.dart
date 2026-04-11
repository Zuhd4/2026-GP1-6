import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  static const Color primaryBlue = Color(0xFF5B96CA);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color softPeach = Color(0xFFF1B4AF);
  static const Color softGrey = Color(0xFFF8F9FB);
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  void _showComingSoon(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF9E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('🚀', style: TextStyle(fontSize: 28.sp)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature will be available soon!',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.black45,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
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

  Widget _actionButton(
    BuildContext context,
    String text,
    IconData icon,
    double sw,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => _showComingSoon(context),
          icon: Icon(icon, size: 20),
          label: Text(
            text,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: textDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepItem(String emoji, String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: textDark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final hPad = sw * 0.055;
    final double topPad = mq.padding.top + 76;
    final double bottomPad = mq.padding.bottom + 96;

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Books',
                  style: GoogleFonts.montserrat(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w500,
                    color: textDark.withOpacity(0.9),
                  ),
                ),
                Text(
                  'Scan or upload any text image',
                  style: GoogleFonts.montserrat(
                    fontSize: 12.sp,
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.05,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFBF8FF), Color(0xFFF5FAFF)],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryPurple.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.document_scanner_rounded,
                                color: primaryPurple.withOpacity(0.7),
                                size: 32,
                              ),
                            ),
                            SizedBox(width: sw * 0.04),
                            Expanded(
                              child: Text(
                                'Scan or upload\nan image',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(sw * 0.05),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(sw * 0.045),
                              decoration: BoxDecoration(
                                color: softGrey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🗺️ How it works',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _stepItem(
                                    '📸',
                                    'Scan text from a book',
                                    softPeach,
                                  ),
                                  _stepItem(
                                    '🖼️',
                                    'Upload an image',
                                    primaryBlue,
                                  ),
                                  _stepItem(
                                    '🔤',
                                    'Convert to readable text',
                                    primaryGreen,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _actionButton(
                                    context,
                                    'Scan',
                                    Icons.camera_alt_rounded,
                                    sw,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _actionButton(
                                    context,
                                    'Upload',
                                    Icons.file_upload_outlined,
                                    sw,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
