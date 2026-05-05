import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/lexia_popup.dart';
import 'responsive_helper.dart';

class MyBookPage extends StatelessWidget {
  const MyBookPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  void _comingSoon(BuildContext context) {
    LexiaPopup.showMessage(
      context: context,
      title: 'Coming Soon!',
      message: 'This document will be available soon!',
      emoji: '🚀',
      buttonColor: primaryPurple,
      buttonText: 'Got it!',
    );
  }

  Future<void> _showLockedPopup(BuildContext context) async {
    await LexiaPopup.showMessage(
      context: context,
      title: 'Coming Soon!',
      message: 'This feature will be available soon.',
      emoji: '🚀',
      buttonColor: primaryPurple,
      buttonText: 'Got it!',
      barrierDismissible: false,
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

        /// مهم: بدون R.pageWrap هنا
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
                'My Book',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(21),
                  fontWeight: FontWeight.w500,
                  color: textDark.withOpacity(0.9),
                ),
              ),

              SizedBox(height: R.space(28)),

              GestureDetector(
                onTap: () => _showLockedPopup(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.space(14)),
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
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: R.icon(58),
                            height: R.icon(58),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E4F8).withOpacity(0.75),
                              borderRadius: BorderRadius.circular(R.radius(16)),
                            ),
                            child: Icon(
                              Icons.description_rounded,
                              size: R.icon(30),
                              color: primaryPurple.withOpacity(0.45),
                            ),
                          ),
                          Icon(
                            Icons.lock_outline_rounded,
                            size: R.icon(22),
                            color: textDark.withOpacity(0.45),
                          ),
                        ],
                      ),

                      SizedBox(width: R.space(12)),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monkey Story',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(14),
                                fontWeight: FontWeight.w600,
                                color: textDark.withOpacity(0.45),
                              ),
                            ),
                            SizedBox(height: R.space(4)),
                            Text(
                              'Sent by parent',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(11),
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.lock_rounded,
                        size: R.icon(18),
                        color: Colors.black26,
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
