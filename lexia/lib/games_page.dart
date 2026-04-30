import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/trail_painter.dart';
import 'widgets/level_node.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: primaryPurple),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
              child: Center(
                child: Text(
                  "Please add a child profile first",
                  style: GoogleFonts.montserrat(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ),
            ),
          );
        }

        final childDoc = snapshot.data!.docs.first;
        final childData = childDoc.data();

        final String childId = childDoc.id;

        return _GamesMapContent(childId: childId, childData: childData);
      },
    );
  }
}

class _GamesMapContent extends StatelessWidget {
  final String childId;
  final Map<String, dynamic> childData;

  const _GamesMapContent({required this.childId, required this.childData});

  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  Map<String, dynamic> get _gameProgress {
    return Map<String, dynamic>.from(childData['gameProgress'] ?? {});
  }

  Map<String, dynamic> _levelProgress(int level) {
    final String levelKey = 'level_$level';
    return Map<String, dynamic>.from(_gameProgress[levelKey] ?? {});
  }

  Map<String, dynamic> _gameData(int level, String gameKey) {
    final levelProgress = _levelProgress(level);
    return Map<String, dynamic>.from(levelProgress[gameKey] ?? {});
  }

  bool _isGameCompleted(int level, String gameKey) {
    final game = _gameData(level, gameKey);
    return game['completed'] == true;
  }

  int _gameBestStars(int level, String gameKey) {
    final game = _gameData(level, gameKey);
    return ((game['bestStars'] as num?)?.toInt() ?? 0).clamp(0, 3);
  }

  int get _totalStars {
    int total = 0;

    for (int level = 1; level <= 6; level++) {
      total += _gameBestStars(level, 'letterScramble');
    }

    return total.clamp(0, 18);
  }

  int get _completedLevels {
    int count = 0;

    for (int level = 1; level <= 6; level++) {
      if (_isGameCompleted(level, 'letterScramble')) {
        count++;
      }
    }

    return count.clamp(0, 6);
  }

  String _levelStatus(int level) {
    // Level 1 always starts unlocked.
    if (level == 1) {
      return _isGameCompleted(1, 'letterScramble') ? "completed" : "current";
    }

    // A level opens only if the previous level's Letter Scramble is completed.
    final bool previousLevelCompleted = _isGameCompleted(
      level - 1,
      'letterScramble',
    );

    if (!previousLevelCompleted) {
      return "locked";
    }

    // If the current level's Letter Scramble is completed, mark it completed.
    final bool currentLevelCompleted = _isGameCompleted(
      level,
      'letterScramble',
    );

    if (currentLevelCompleted) {
      return "completed";
    }

    return "current";
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top + 84.h;

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
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Container(
            decoration: BoxDecoration(
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

                          _node(
                            1,
                            "",
                            _levelStatus(1),
                            const Color(0xFF7D99D4),
                            sw * 0.45,
                            1400.h,
                            topPadding,
                          ),

                          _node(
                            2,
                            "",
                            _levelStatus(2),
                            const Color(0xFFF1B0AB),
                            sw * 0.25,
                            1150.h,
                            topPadding,
                          ),

                          _node(
                            3,
                            "",
                            _levelStatus(3),
                            const Color(0xFF5BAE94),
                            sw * 0.65,
                            900.h,
                            topPadding,
                          ),

                          _node(
                            4,
                            "",
                            _levelStatus(4),
                            const Color(0xFF94A3B8),
                            sw * 0.30,
                            650.h,
                            topPadding,
                          ),

                          _node(
                            5,
                            "",
                            _levelStatus(5),
                            const Color(0xFF94A3B8),
                            sw * 0.60,
                            400.h,
                            topPadding,
                          ),

                          _node(
                            6,
                            "",
                            _levelStatus(6),
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
    int level,
    String title,
    String status,
    Color color,
    double x,
    double y,
    double topPadding,
  ) {
    return LevelNode(
      level: level,
      title: title,
      status: status,
      color: color,
      position: Offset(x, y + topPadding),
      childId: childId,
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
                "$_totalStars/18",
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
                "$_completedLevels/6",
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            "$_completedLevels/6 levels",
            style: GoogleFonts.montserrat(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142).withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
