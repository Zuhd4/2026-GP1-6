import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/trail_painter.dart';
import 'widgets/level_node.dart';

class GamesPage extends StatelessWidget {
  final String childId;

  const GamesPage({super.key, required this.childId});

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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
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

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _emptyMessage("Child profile not found");
        }

        final childDoc = snapshot.data!;
        final childData = childDoc.data() ?? {};

        return _GamesMapContent(childId: childDoc.id, childData: childData);
      },
    );
  }

  Widget _emptyMessage(String message) {
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
          ),
        ),
        child: Center(
          child: Text(
            message,
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
}

class _GamesMapContent extends StatefulWidget {
  final String childId;
  final Map<String, dynamic> childData;

  const _GamesMapContent({required this.childId, required this.childData});

  @override
  State<_GamesMapContent> createState() => _GamesMapContentState();
}

class _GamesMapContentState extends State<_GamesMapContent> {
  final ScrollController _scrollController = ScrollController();
  bool _didAutoScroll = false;

  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);

  Map<String, dynamic> get childData => widget.childData;
  String get childId => widget.childId;

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

  int get _totalTrophies {
    return ((childData['trophies'] as num?)?.toInt() ?? 0).clamp(0, 6);
  }

  List<int> get _completedTrophyLevels {
    final list = (childData['completedTrophyLevels'] as List?) ?? [];

    return list
        .map((e) {
          if (e is num) return e.toInt();
          return int.tryParse(e.toString()) ?? 0;
        })
        .where((level) => level >= 1 && level <= 6)
        .toList();
  }

  String _levelStatus(int level) {
    if (level == 1) {
      return _isGameCompleted(1, 'letterScramble') ? "completed" : "current";
    }

    final previousLevelCompleted = _isGameCompleted(
      level - 1,
      'letterScramble',
    );

    if (!previousLevelCompleted) return "locked";

    final currentLevelCompleted = _isGameCompleted(level, 'letterScramble');

    if (currentLevelCompleted) return "completed";

    return "current";
  }

  int get _currentLevel {
    for (int level = 1; level <= 6; level++) {
      if (_levelStatus(level) == "current") return level;
    }
    return 6;
  }

  double _levelYPosition(int level) {
    switch (level) {
      case 1:
        return 1400.h;
      case 2:
        return 1150.h;
      case 3:
        return 900.h;
      case 4:
        return 650.h;
      case 5:
        return 400.h;
      case 6:
        return 150.h;
      default:
        return 1400.h;
    }
  }

  void _scrollToCurrentLevel(double topPadding) {
    if (_didAutoScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final screenHeight = MediaQuery.of(context).size.height;
      final targetY = _levelYPosition(_currentLevel) + topPadding;

      final targetOffset = (targetY - (screenHeight * 0.45)).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );

      _didAutoScroll = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final mq = MediaQuery.of(context);
    final topPadding = mq.padding.top + 84.h;

    _scrollToCurrentLevel(topPadding);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFFFAF0),
              Color(0xFFF7F3FF),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFCF6),
                  Color(0xFFFFF7FB),
                  Color(0xFFF7F3FF),
                  Colors.white,
                ],
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
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: 1850.h + topPadding,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: TrailPainter(
                                currentLevel: _currentLevel,
                              ),
                            ),
                          ),
                          _node(
                            1,
                            _levelStatus(1),
                            const Color(0xFF7D99D4),
                            sw * 0.45,
                            1400.h,
                            topPadding,
                          ),
                          _node(
                            2,
                            _levelStatus(2),
                            const Color(0xFFF1B0AB),
                            sw * 0.25,
                            1150.h,
                            topPadding,
                          ),
                          _node(
                            3,
                            _levelStatus(3),
                            const Color(0xFF59A685),
                            sw * 0.65,
                            900.h,
                            topPadding,
                          ),
                          _node(
                            4,
                            _levelStatus(4),
                            primaryPurple,
                            sw * 0.30,
                            650.h,
                            topPadding,
                          ),
                          _node(
                            5,
                            _levelStatus(5),
                            const Color(0xFFF1B4AF),
                            sw * 0.60,
                            400.h,
                            topPadding,
                          ),
                          _node(
                            6,
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
                    left: 14.w,
                    child: _buildProgressCards(),
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
    String status,
    Color color,
    double x,
    double y,
    double topPadding,
  ) {
    return LevelNode(
      level: level,
      status: status,
      color: color,
      position: Offset(x, y + topPadding),
      childId: childId,
      hasTrophy: _completedTrophyLevels.contains(level),
      stars: _gameBestStars(level, 'letterScramble'),
    );
  }

  Widget _buildProgressCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniCard(
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber,
          title: "Trophies",
          value: "$_totalTrophies/6",
          bgColor: const Color(0xFFFFF8E1),
        ),
        SizedBox(height: 8.h),
        _miniCard(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          title: "Stars",
          value: "$_totalStars",
          bgColor: const Color(0xFFFFF3F7),
        ),
      ],
    );
  }

  Widget _miniCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      width: 112.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: iconColor.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 33.w,
            height: 33.w,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w700,
                  color: textDark.withOpacity(0.48),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.fredoka(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
