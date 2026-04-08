import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      "Reading",
      style: GoogleFonts.montserrat(
        fontSize: 26.sp,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2D3142),
      ),
    ),
  );
}
