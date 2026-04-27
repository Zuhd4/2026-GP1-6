import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'letter_scramble_page.dart';

class GamesSelectionPage extends StatelessWidget {
  final int level;

  const GamesSelectionPage({super.key, required this.level});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  static const Color coral = Color.fromARGB(255, 230, 157, 153);
  static const Color blue = Color(0xFF5B96CA);
  static const Color green = Color(0xFF59A685);

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Coming Soon!",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryPurple.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
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
            padding: EdgeInsets.fromLTRB(22.w, 16.h, 22.w, 28.h),
            child: Column(
              children: [
                _buildTopBar(context),
                SizedBox(height: 18.h),

                Text(
                  "Level $level Games",
                  style: GoogleFonts.fredoka(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  "Choose a game to practice",
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: textDark.withOpacity(0.55),
                  ),
                ),

                SizedBox(height: 22.h),

                _buildCharacter(),

                SizedBox(height: 26.h),

                _GameCard(
                  title: "Letter Scramble",
                  subtitle: "Arrange the letters to form the correct word.",
                  emoji: "🧩",
                  color: coral,
                  isLarge: true,
                  buttonText: "Play",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LetterScramblePage(level: level),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: _GameCard(
                        title: "Listen\nand Spell",
                        subtitle: "Listen carefully and spell the word.",
                        emoji: "🎧",
                        color: green,
                        buttonText: "Coming Soon",
                        isLocked: true,
                        onTap: () => _showComingSoon(context),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _GameCard(
                        title: "Word\nMatching",
                        subtitle: "Match the word with the picture.",
                        emoji: "✨",
                        color: blue,
                        buttonText: "Coming Soon",
                        isLocked: true,
                        onTap: () => _showComingSoon(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.r,
              color: primaryPurple,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Image.asset(
        "assets/e_happy.png",
        height: 140.h,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final String buttonText;
  final bool isLocked;
  final bool isLarge;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.buttonText,
    required this.onTap,
    this.isLocked = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLarge ? 18.w : 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: isLarge ? _largeLayout() : _smallLayout(),
      ),
    );
  }

  Widget _largeLayout() {
    return Row(
      children: [
        _iconBox(70),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleText(fontSize: 22),
              SizedBox(height: 6.h),
              _subtitleText(),
              SizedBox(height: 14.h),
              _button(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallLayout() {
    return Column(
      children: [
        if (isLocked)
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.lock_rounded,
              color: color.withOpacity(0.6),
              size: 18.r,
            ),
          ),
        _iconBox(56),
        SizedBox(height: 10.h),
        _titleText(fontSize: 18, center: true),
        SizedBox(height: 8.h),
        _subtitleText(center: true),
        SizedBox(height: 14.h),
        _button(),
      ],
    );
  }

  Widget _iconBox(double size) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: (size * 0.42).sp)),
      ),
    );
  }

  Widget _titleText({required double fontSize, bool center = false}) {
    return Text(
      title,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.fredoka(
        fontSize: fontSize.sp,
        fontWeight: FontWeight.bold,
        height: 1.05,
        color: color,
      ),
    );
  }

  Widget _subtitleText({bool center = false}) {
    return Text(
      subtitle,
      textAlign: center ? TextAlign.center : TextAlign.start,
      maxLines: isLarge ? 2 : 3,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(
        fontSize: isLarge ? 12.sp : 10.5.sp,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: const Color(0xFF2D3142).withOpacity(0.55),
      ),
    );
  }

  Widget _button() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isLarge ? 11.h : 9.h),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade300 : color,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        buttonText,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: isLarge ? 13.sp : 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
