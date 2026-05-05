import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../responsive_helper.dart';

class LexiaPopup {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color green = Color(0xFF59A685);

  static Future<void> showMessage({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    String? emoji,
    Color iconColor = primaryPurple,
    Color buttonColor = green,
    String buttonText = "Got it",
    bool barrierDismissible = true,
    VoidCallback? onDone,
  }) async {
    R.init(context);

    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
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
              physics: const BouncingScrollPhysics(),
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
                        child: emoji != null
                            ? Text(
                                emoji,
                                style: TextStyle(fontSize: R.text(28)),
                              )
                            : Icon(
                                icon ?? Icons.info_outline_rounded,
                                color: iconColor,
                                size: R.icon(32),
                              ),
                      ),
                    ),

                    SizedBox(height: R.space(16)),

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(18),
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),

                    SizedBox(height: R.space(8)),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(12),
                        fontWeight: FontWeight.w400,
                        color: Colors.black45,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: R.space(22)),

                    SizedBox(
                      width: double.infinity,
                      height: R.buttonH(48),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDone?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(R.radius(14)),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(13),
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
          ),
        ),
      ),
    );
  }

  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = "Cancel",
    String confirmText = "Confirm",
    Color confirmColor = primaryPurple,
    IconData icon = Icons.help_outline_rounded,
    Color iconColor = primaryPurple,
  }) async {
    R.init(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
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
              physics: const BouncingScrollPhysics(),
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
                        child: Icon(icon, color: iconColor, size: R.icon(32)),
                      ),
                    ),

                    SizedBox(height: R.space(16)),

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(18),
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),

                    SizedBox(height: R.space(8)),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(12),
                        fontWeight: FontWeight.w400,
                        color: Colors.black45,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: R.space(22)),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              cancelText,
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(12),
                                fontWeight: FontWeight.w500,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: R.space(10)),

                        Expanded(
                          child: SizedBox(
                            height: R.buttonH(46),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(14),
                                  ),
                                ),
                              ),
                              child: Text(
                                confirmText,
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
        ),
      ),
    );

    return result == true;
  }
}
