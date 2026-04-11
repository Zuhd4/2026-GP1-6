import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/trail_painter.dart';
import 'widgets/level_node.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  // --- DASHBOARD BACKGROUND COLORS ---
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top + 84.h;

    return Scaffold(
      // Set to transparent so the Container's gradient shows
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // THE DASHBOARD THREE-POINT SOFT GRADIENT
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Container(
            decoration: BoxDecoration(
              // --- YOUR MAP CARD GRADIENT ---
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 250, 254, 248), Colors.white],
              ),
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32.r),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: 1850.h + topPadding,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: TrailPainter()),
                          ),

                          // --- 6 LEVELS PLACED ON THE S-CURVE ---
                          _node(
                            1,
                            "Letter Fun",
                            "completed",
                            const Color(0xFF7D99D4),
                            sw * 0.45,
                            1400.h,
                            topPadding,
                          ),
                          _node(
                            2,
                            "Sound Match",
                            "completed",
                            const Color(0xFFF1B0AB),
                            sw * 0.25,
                            1150.h,
                            topPadding,
                          ),
                          _node(
                            3,
                            "Word Build",
                            "current",
                            const Color(0xFF5BAE94),
                            sw * 0.65,
                            900.h,
                            topPadding,
                          ),
                          _node(
                            4,
                            "Silly Story",
                            "locked",
                            const Color(0xFF94A3B8),
                            sw * 0.30,
                            650.h,
                            topPadding,
                          ),
                          _node(
                            5,
                            "Read Along",
                            "locked",
                            const Color(0xFF94A3B8),
                            sw * 0.60,
                            400.h,
                            topPadding,
                          ),
                          _node(
                            6,
                            "Super Star!",
                            "locked",
                            const Color(0xFFFACC15),
                            sw * 0.45,
                            150.h,
                            topPadding,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: topPadding + 8.h,
                    left: 20.w,
                    child: _buildProgressBadge(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LevelNode _node(
    int lv,
    String t,
    String s,
    Color c,
    double x,
    double y,
    double pad,
  ) {
    return LevelNode(
      level: lv,
      title: t,
      status: s,
      color: c,
      position: Offset(x, y + pad),
    );
  }

  Widget _buildProgressBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              SizedBox(width: 4.w),
              Text(
                "5/18",
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.orange, size: 18),
              SizedBox(width: 4.w),
              Text(
                "3/6",
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
