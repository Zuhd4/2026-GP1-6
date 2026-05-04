import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_child_page.dart';
import 'responsive_helper.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final double horizontalPad = R.pagePad;

    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(105);

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: primaryPurple),
            ),
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final String parentName = userData?['name'] ?? 'Parent';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('children')
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

            final bool hasChild =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            final List<String> childNames = hasChild
                ? snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['name']?.toString() ?? '';
                  }).toList()
                : [];

            final String childrenText = childNames.isEmpty
                ? "Track learning journey"
                : "✨ Track ${childNames.join(' & ')}'s journey";

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
                child: R.pageWrap(
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
                          'Hello $parentName',
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(21),
                            fontWeight: FontWeight.w500,
                            color: textDark.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: R.space(2)),
                        Text(
                          childrenText,
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(12),
                            color: Colors.black45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: R.space(28)),

                        if (hasChild)
                          Column(
                            children: snapshot.data!.docs.map((doc) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: R.space(26)),
                                child: _ChildDashboardCard(doc: doc),
                              );
                            }).toList(),
                          )
                        else
                          const _EmptyStateCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChildDashboardCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const _ChildDashboardCard({required this.doc});

  @override
  State<_ChildDashboardCard> createState() => _ChildDashboardCardState();
}

class _ChildDashboardCardState extends State<_ChildDashboardCard> {
  late int displayedLevel;

  @override
  void initState() {
    super.initState();
    displayedLevel = _getCurrentUnlockedLevel();
  }

  int _getCurrentUnlockedLevel() {
    final data = widget.doc.data() as Map<String, dynamic>;
    final gameProgress = Map<String, dynamic>.from(data['gameProgress'] ?? {});

    int unlockedLevel = 1;

    for (int level = 1; level <= 6; level++) {
      final levelKey = 'level_$level';

      final levelProgress = Map<String, dynamic>.from(
        gameProgress[levelKey] ?? {},
      );

      final letterScramble = Map<String, dynamic>.from(
        levelProgress['letterScramble'] ?? {},
      );

      final bool completed = letterScramble['completed'] == true;

      if (completed && level < 6) {
        unlockedLevel = level + 1;
      }
    }

    return unlockedLevel.clamp(1, 6);
  }

  Map<String, dynamic> _getLetterScrambleData(int level) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final gameProgress = Map<String, dynamic>.from(data['gameProgress'] ?? {});

    final levelKey = 'level_$level';

    final levelProgress = Map<String, dynamic>.from(
      gameProgress[levelKey] ?? {},
    );

    return Map<String, dynamic>.from(levelProgress['letterScramble'] ?? {});
  }

  bool _isLetterScrambleCompleted(int level) {
    final letterData = _getLetterScrambleData(level);
    return letterData['completed'] == true;
  }

  int _bestStarsForLetterScramble(int level) {
    final letterData = _getLetterScrambleData(level);
    return ((letterData['bestStars'] as num?)?.toInt() ?? 0).clamp(0, 3);
  }

  bool _isLevelLocked(int level) {
    if (level == 1) return false;
    return !_isLetterScrambleCompleted(level - 1);
  }

  double _levelProgressValue(int level) {
    if (_isLevelLocked(level)) return 0.0;
    return _isLetterScrambleCompleted(level) ? 1.0 : 0.0;
  }

  Widget _avatarWidget(String? path, {double size = 44}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;

    if (src.endsWith('.svg')) {
      return SvgPicture.asset(
        src,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(R.radius(12)),
      child: Image.asset(src, width: size, height: size, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String childName = data['name'] ?? 'Child';
    final String? avatarUrl = data['avatarUrl'];

    final int currentUnlockedLevel = _getCurrentUnlockedLevel();
    final bool levelLocked = _isLevelLocked(displayedLevel);
    final bool letterCompleted = _isLetterScrambleCompleted(displayedLevel);
    final int letterStars = _bestStarsForLetterScramble(displayedLevel);

    final double levelProgress = _levelProgressValue(displayedLevel);

    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(R.space(14)),
            child: Row(
              children: [
                _avatarWidget(avatarUrl, size: R.icon(44)),
                SizedBox(width: R.space(11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: GoogleFonts.montserrat(
                          fontSize: R.text(17),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      SizedBox(height: R.space(4)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.space(8),
                          vertical: R.space(3),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4F8),
                          borderRadius: BorderRadius.circular(R.radius(8)),
                        ),
                        child: Text(
                          'Current Level $currentUnlockedLevel/6',
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(10),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6A5ACD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: R.space(14)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Level $displayedLevel Progress',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500,
                          fontSize: R.text(13),
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: R.icon(30),
                        minHeight: R.icon(30),
                      ),
                      onPressed: () => setState(() {
                        if (displayedLevel > 1) displayedLevel--;
                      }),
                      icon: Icon(Icons.chevron_left_rounded, size: R.icon(20)),
                    ),
                    Text(
                      '$displayedLevel',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: R.text(13),
                        color: const Color(0xFF6A5ACD),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: R.icon(30),
                        minHeight: R.icon(30),
                      ),
                      onPressed: () => setState(() {
                        if (displayedLevel < 6) displayedLevel++;
                      }),
                      icon: Icon(Icons.chevron_right_rounded, size: R.icon(20)),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(R.radius(12)),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: R.space(8),
                    backgroundColor: const Color(0xFFF3F4F8),
                    color: const Color(0xFF6A5ACD),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(R.space(14)),
            child: Column(
              children: [
                _GameCard(
                  title: 'Letter Scramble',
                  emoji: '🧩',
                  color: const Color(0xFFF1B4AF),
                  score: levelLocked
                      ? '0/3'
                      : letterCompleted
                      ? '$letterStars/3'
                      : '0/3',
                  status: levelLocked
                      ? 'Locked'
                      : letterCompleted
                      ? 'Completed'
                      : 'Not started',
                  isLocked: levelLocked,
                  isCompleted: letterCompleted && !levelLocked,
                ),
                SizedBox(height: R.space(9)),
                const _GameCard(
                  title: 'Word Matching',
                  emoji: '✨',
                  color: Color(0xFF5B96CA),
                  score: '0/3',
                  status: 'Locked',
                  isLocked: true,
                ),
                SizedBox(height: R.space(9)),
                const _GameCard(
                  title: 'Listen and Spell',
                  emoji: '🎧',
                  color: Color(0xFF59A685),
                  score: '0/3',
                  status: 'Locked',
                  isLocked: true,
                ),
              ],
            ),
          ),

          const _StoryGrid(isLocked: true),
          SizedBox(height: R.space(18)),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String score;
  final String status;
  final Color color;
  final bool isLocked;
  final bool isCompleted;

  const _GameCard({
    required this.title,
    required this.emoji,
    required this.color,
    required this.score,
    required this.status,
    this.isLocked = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isCompleted
        ? const Color(0xFF59A685)
        : isLocked
        ? Colors.black26
        : Colors.black38;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(10),
        vertical: R.space(8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(12)),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF59A685).withOpacity(0.35)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: R.icon(31),
            height: R.icon(31),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(R.radius(8)),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: R.text(14))),
            ),
          ),
          SizedBox(width: R.space(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: R.text(12),
                    color: const Color(0xFF2D3142),
                  ),
                ),
                SizedBox(height: R.space(1)),
                Text(
                  status,
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(10),
                    color: statusColor,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked)
            Icon(Icons.lock_rounded, size: R.icon(16), color: Colors.black26)
          else if (isCompleted)
            Row(
              children: [
                Text(
                  score,
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(11),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF59A685),
                  ),
                ),
                SizedBox(width: R.space(5)),
                Icon(
                  Icons.check_circle_rounded,
                  size: R.icon(16),
                  color: const Color(0xFF59A685),
                ),
              ],
            )
          else
            Text(
              score,
              style: GoogleFonts.montserrat(
                fontSize: R.text(11),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6A5ACD),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryGrid extends StatelessWidget {
  final bool isLocked;

  const _StoryGrid({this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stories = [
      {'name': 'Butterfly', 'emoji': '🦋', 'color': const Color(0xFFE8F5E9)},
      {'name': 'Sky', 'emoji': '✈️', 'color': const Color(0xFFE3F2FD)},
      {'name': 'Stars', 'emoji': '✨', 'color': const Color(0xFFF3E5F5)},
      {'name': 'Moon', 'emoji': '🌙', 'color': const Color(0xFFE1F5FE)},
      {'name': 'Dragon', 'emoji': '🐉', 'color': const Color(0xFFF1F8E9)},
      {'name': 'Ocean', 'emoji': '🐠', 'color': const Color(0xFFE0F7FA)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: R.space(14),
            vertical: R.space(8),
          ),
          child: Text(
            'Recent Stories',
            style: GoogleFonts.montserrat(
              fontSize: R.text(13),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3142),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stories.length,
          padding: EdgeInsets.symmetric(horizontal: R.space(14)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: R.sw < 340 ? 2 : 3,
            crossAxisSpacing: R.space(10),
            mainAxisSpacing: R.space(12),
            childAspectRatio: R.sw < 340 ? 0.95 : 0.9,
          ),
          itemBuilder: (context, index) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: stories[index]['color'],
                      borderRadius: BorderRadius.circular(R.radius(14)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: isLocked ? 0.45 : 1,
                            child: Text(
                              stories[index]['emoji'],
                              style: TextStyle(fontSize: R.text(23)),
                            ),
                          ),
                        ),
                        if (isLocked)
                          Positioned(
                            top: R.space(6),
                            right: R.space(6),
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.black26,
                              size: R.icon(17),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: R.space(7)),
                Text(
                  stories[index]['name'],
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(10),
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.space(22)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(22)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.child_care_rounded,
            size: R.icon(44),
            color: const Color(0xFF6A5ACD),
          ),
          SizedBox(height: R.space(12)),
          Text(
            'Add a child profile',
            style: GoogleFonts.montserrat(
              fontSize: R.text(17),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: R.space(15)),
          SizedBox(
            width: double.infinity,
            height: R.buttonH(50),
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddChildPage(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(16)),
                ),
              ),
              child: Text(
                'Add Child',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
