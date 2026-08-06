import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  /// Returns OpenDyslexic font style if [useOpenDyslexic] is true,
  /// otherwise defaults to Montserrat.
  static TextStyle getStyle({
    required bool useOpenDyslexic,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    if (useOpenDyslexic) {
      return TextStyle(
        fontFamily: 'OpenDyslexic',
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } else {
      return GoogleFonts.montserrat(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }
}
