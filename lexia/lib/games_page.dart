import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      "Games",
      style: GoogleFonts.montserrat(
        fontSize: 26.sp,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2D3142),
      ),
    ),
  );
}
