import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_helper.dart';

/// Shows the raw text extracted from a scanned/uploaded page.
/// Difficulty-word highlighting will be layered on top of this text
/// in a later step once the scoring rules are ported.
class ScanResultPage extends StatelessWidget {
  final String documentName;
  final String extractedText;

  const ScanResultPage({
    super.key,
    required this.documentName,
    required this.extractedText,
  });

  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          documentName,
          style: GoogleFonts.montserrat(
            fontSize: R.text(16),
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
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
            padding: EdgeInsets.fromLTRB(
              R.pagePad,
              R.space(16),
              R.pagePad,
              R.space(40),
            ),
            child: extractedText.trim().isEmpty
                ? _emptyState()
                : Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(R.space(18)),
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
                    child: Text(
                      extractedText,
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(15),
                        height: 1.6,
                        color: textDark,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: R.space(40)),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.text_snippet_outlined,
            color: Colors.black26,
            size: R.icon(36),
          ),
          SizedBox(height: R.space(10)),
          Text(
            'No text was detected in this image',
            style: GoogleFonts.montserrat(
              fontSize: R.text(13),
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
