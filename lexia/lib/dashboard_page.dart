import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

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
                      _DashboardHeader(
                        parentName: parentName,

                        childrenText: childrenText,
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
            );
          },
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String parentName;

  final String childrenText;

  const _DashboardHeader({
    required this.parentName,

    required this.childrenText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Hello $parentName',

          style: GoogleFonts.montserrat(
            fontSize: R.text(21),

            fontWeight: FontWeight.w500,

            color: DashboardPage.textDark.withOpacity(0.9),
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
      ],
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

      final wordMatching = Map<String, dynamic>.from(
        levelProgress['wordMatching'] ?? {},
      );

      final listenAndSpell = Map<String, dynamic>.from(
        levelProgress['listenAndSpell'] ?? {},
      );

      final bool levelFullyCompleted =
          letterScramble['completed'] == true &&
          wordMatching['completed'] == true &&
          listenAndSpell['completed'] == true;

      if (levelFullyCompleted && level < 6) {
        unlockedLevel = level + 1;
      }
    }

    return unlockedLevel.clamp(1, 6);
  }

  Map<String, dynamic> _getLevelProgress(int level) {
    final data = widget.doc.data() as Map<String, dynamic>;

    final gameProgress = Map<String, dynamic>.from(data['gameProgress'] ?? {});

    final levelKey = 'level_$level';

    return Map<String, dynamic>.from(gameProgress[levelKey] ?? {});
  }

  Map<String, dynamic> _getGameData(int level, String gameKey) {
    final levelProgress = _getLevelProgress(level);

    return Map<String, dynamic>.from(levelProgress[gameKey] ?? {});
  }

  bool _isGameCompleted(int level, String gameKey) {
    final gameData = _getGameData(level, gameKey);

    return gameData['completed'] == true;
  }

  int _bestStarsForGame(int level, String gameKey) {
    final gameData = _getGameData(level, gameKey);

    return ((gameData['bestStars'] as num?)?.toInt() ?? 0).clamp(0, 3);
  }

  /// Calculates total trophies collected (levels where all 3 games achieved 3/3 stars)

  int _totalTrophiesCollected() {
    int trophies = 0;

    for (int level = 1; level <= 6; level++) {
      if (_bestStarsForGame(level, 'letterScramble') == 3 &&
          _bestStarsForGame(level, 'wordMatching') == 3 &&
          _bestStarsForGame(level, 'listenAndSpell') == 3) {
        trophies++;
      }
    }

    return trophies.clamp(0, 6);
  }

  bool _isLevelLocked(int level) {
    if (level == 1) return false;

    return !_isGameCompleted(level - 1, 'letterScramble') ||
        !_isGameCompleted(level - 1, 'wordMatching') ||
        !_isGameCompleted(level - 1, 'listenAndSpell');
  }

  double _levelProgressValue(int level) {
    if (_isLevelLocked(level)) return 0.0;

    int completedGamesCount = 0;

    if (_isGameCompleted(level, 'letterScramble')) completedGamesCount++;

    if (_isGameCompleted(level, 'wordMatching')) completedGamesCount++;

    if (_isGameCompleted(level, 'listenAndSpell')) completedGamesCount++;

    return completedGamesCount / 3.0;
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

  Widget _trophyBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(9),

        vertical: R.space(6),
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(R.radius(14)),

        border: Border.all(color: Colors.amber.withOpacity(0.25), width: 1),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),

            blurRadius: 8,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: R.icon(26),

            height: R.icon(26),

            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),

              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.emoji_events_rounded,

              color: Colors.amber,

              size: R.icon(16),
            ),
          ),

          SizedBox(width: R.space(5)),

          Text(
            '$count/6',

            style: GoogleFonts.montserrat(
              fontSize: R.text(12),

              fontWeight: FontWeight.w600,

              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;

    final String childName = data['name'] ?? 'Child';

    final String? avatarUrl = data['avatarUrl'];

    final Map<String, dynamic> readingProgress = Map<String, dynamic>.from(
      data['readingProgress'] ?? {},
    );

    final int currentUnlockedLevel = _getCurrentUnlockedLevel();

    final int totalTrophies = _totalTrophiesCollected();

    final bool levelLocked = _isLevelLocked(displayedLevel);

    // Game Statuses

    final bool letterCompleted = _isGameCompleted(
      displayedLevel,

      'letterScramble',
    );

    final int letterStars = _bestStarsForGame(displayedLevel, 'letterScramble');

    final bool wordMatchingCompleted = _isGameCompleted(
      displayedLevel,

      'wordMatching',
    );

    final int wordMatchingStars = _bestStarsForGame(
      displayedLevel,

      'wordMatching',
    );

    final bool listenSpellCompleted = _isGameCompleted(
      displayedLevel,

      'listenAndSpell',
    );

    final int listenSpellStars = _bestStarsForGame(
      displayedLevel,

      'listenAndSpell',
    );

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

                _trophyBadge(totalTrophies),
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

                _GameCard(
                  title: 'Word Matching',

                  emoji: '✨',

                  color: const Color(0xFF5B96CA),

                  score: levelLocked
                      ? '0/3'
                      : wordMatchingCompleted
                      ? '$wordMatchingStars/3'
                      : '0/3',

                  status: levelLocked
                      ? 'Locked'
                      : wordMatchingCompleted
                      ? 'Completed'
                      : 'Not started',

                  isLocked: levelLocked,

                  isCompleted: wordMatchingCompleted && !levelLocked,
                ),

                SizedBox(height: R.space(9)),

                _GameCard(
                  title: 'Listen and Spell',

                  emoji: '🎧',

                  color: const Color(0xFF59A685),

                  score: levelLocked
                      ? '0/3'
                      : listenSpellCompleted
                      ? '$listenSpellStars/3'
                      : '0/3',

                  status: levelLocked
                      ? 'Locked'
                      : listenSpellCompleted
                      ? 'Completed'
                      : 'Not started',

                  isLocked: levelLocked,

                  isCompleted: listenSpellCompleted && !levelLocked,
                ),
              ],
            ),
          ),

          _ReadingProgressSection(readingProgress: readingProgress),

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

class _ReadingProgressSection extends StatefulWidget {
  final Map<String, dynamic> readingProgress;

  const _ReadingProgressSection({required this.readingProgress});

  @override
  State<_ReadingProgressSection> createState() =>
      _ReadingProgressSectionState();
}

class _ReadingProgressSectionState extends State<_ReadingProgressSection> {
  late int selectedLevel;

  @override
  void initState() {
    super.initState();

    // Always start with Book 1 selected.
    selectedLevel = 1;
  }

  @override
  void didUpdateWidget(covariant _ReadingProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Keep whichever story the parent selected.
    // Only reset if the value somehow becomes invalid.
    if (selectedLevel < 1 || selectedLevel > 6) {
      selectedLevel = 1;
    }
  }

  Map<String, dynamic> _storyData(int level) {
    final levelData = Map<String, dynamic>.from(
      widget.readingProgress['level_$level'] ?? {},
    );

    return Map<String, dynamic>.from(levelData['storyReading'] ?? {});
  }

  double _bestScore(int level) {
    final story = _storyData(level);

    return ((story['bestScore'] as num?)?.toDouble() ?? 0.0);
  }

  bool _isUnlocked(int level) {
    if (level == 1) return true;

    return _bestScore(level - 1) >= 50.0;
  }

  Map<String, dynamic> _visiblePageResults(Map<String, dynamic> story) {
    final current = Map<String, dynamic>.from(
      story['currentPageResults'] ?? {},
    );

    if (current.isNotEmpty) return current;

    return Map<String, dynamic>.from(story['pageResults'] ?? {});
  }

  int _pagesDone(Map<String, dynamic> story) {
    return _visiblePageResults(story).length.clamp(0, 99);
  }

  int _totalPages(Map<String, dynamic> story) {
    final int saved = ((story['totalPages'] as num?)?.toInt() ?? 0);

    return saved > 0 ? saved : 3;
  }

  int _completedStoriesCount() {
    int count = 0;

    for (int level = 1; level <= 6; level++) {
      if (_storyData(level)['completed'] == true) {
        count++;
      }
    }

    return count;
  }

  int _unlockedStoriesCount() {
    int count = 0;

    for (int level = 1; level <= 6; level++) {
      if (_isUnlocked(level)) {
        count++;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final int completedStories = _completedStoriesCount();

    final int unlockedStories = _unlockedStoriesCount();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reading_books')
          .orderBy('level')
          .snapshots(),

      builder: (context, booksSnapshot) {
        final Map<String, Map<String, dynamic>> booksById = {
          for (final doc
              in booksSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            doc.id: doc.data(),
        };

        return Container(
          margin: EdgeInsets.fromLTRB(
            R.space(14),

            R.space(2),

            R.space(14),

            R.space(2),
          ),

          padding: EdgeInsets.all(R.space(14)),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

              colors: [Color(0xFFF8FBF9), Color(0xFFFFFDFB)],
            ),

            borderRadius: BorderRadius.circular(R.radius(20)),

            border: Border.all(
              color: const Color(0xFF59A685).withOpacity(0.14),
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: R.icon(36),

                    height: R.icon(36),

                    decoration: BoxDecoration(
                      color: const Color(0xFF59A685).withOpacity(0.10),

                      borderRadius: BorderRadius.circular(R.radius(10)),
                    ),

                    child: Icon(
                      Icons.auto_stories_rounded,

                      color: const Color(0xFF59A685),

                      size: R.icon(20),
                    ),
                  ),

                  SizedBox(width: R.space(10)),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Reading Progress',

                          style: GoogleFonts.montserrat(
                            fontSize: R.text(14),

                            fontWeight: FontWeight.w600,

                            color: const Color(0xFF2D3142),
                          ),
                        ),

                        SizedBox(height: R.space(2)),

                        Text(
                          '$completedStories of 6 stories completed • $unlockedStories unlocked',

                          style: GoogleFonts.montserrat(
                            fontSize: R.text(9.5),

                            fontWeight: FontWeight.w400,

                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.space(9),

                      vertical: R.space(5),
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF59A685).withOpacity(0.10),

                      borderRadius: BorderRadius.circular(R.radius(12)),
                    ),

                    child: Text(
                      '$completedStories/6',

                      style: GoogleFonts.montserrat(
                        fontSize: R.text(10.5),

                        fontWeight: FontWeight.w700,

                        color: const Color(0xFF59A685),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: R.space(12)),

              ClipRRect(
                borderRadius: BorderRadius.circular(R.radius(10)),

                child: LinearProgressIndicator(
                  value: completedStories / 6.0,

                  minHeight: R.space(7),

                  backgroundColor: const Color(0xFFEDF1EF),

                  color: const Color(0xFF59A685),
                ),
              ),

              SizedBox(height: R.space(14)),

              SizedBox(
                height: R.space(175),

                child: ListView.separated(
                  scrollDirection: Axis.horizontal,

                  physics: const BouncingScrollPhysics(),

                  itemCount: 6,

                  separatorBuilder: (_, __) => SizedBox(width: R.space(10)),

                  itemBuilder: (context, index) {
                    final int level = index + 1;

                    final story = _storyData(level);

                    final book = booksById['book_$level'] ?? {};

                    final bool unlocked = _isUnlocked(level);

                    final String title =
                        (book['title'] ?? story['bookTitle'] ?? 'Story $level')
                            .toString();

                    final String coverPath =
                        (book['cover_image_storage_path'] ?? '').toString();

                    return _ReadingBookProgressCard(
                      level: level,

                      title: title,

                      coverPath: coverPath,

                      storyData: story,

                      isLocked: !unlocked,

                      isSelected: selectedLevel == level,

                      onTap: () {
                        setState(() {
                          selectedLevel = level;
                        });
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: R.space(14)),

              _ReadingStoryDetails(
                level: selectedLevel,

                storyData: _storyData(selectedLevel),

                isLocked: !_isUnlocked(selectedLevel),

                previousBestScore: selectedLevel == 1
                    ? null
                    : _bestScore(selectedLevel - 1),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReadingBookProgressCard extends StatelessWidget {
  final int level;

  final String title;

  final String coverPath;

  final Map<String, dynamic> storyData;

  final bool isLocked;

  final bool isSelected;

  final VoidCallback onTap;

  const _ReadingBookProgressCard({
    required this.level,

    required this.title,

    required this.coverPath,

    required this.storyData,

    required this.isLocked,

    required this.isSelected,

    required this.onTap,
  });

  Map<String, dynamic> _pageResults() {
    final current = Map<String, dynamic>.from(
      storyData['currentPageResults'] ?? {},
    );

    if (current.isNotEmpty) return current;

    return Map<String, dynamic>.from(storyData['pageResults'] ?? {});
  }

  @override
  Widget build(BuildContext context) {
    final bool completed = storyData['completed'] == true;

    final double bestScore =
        ((storyData['bestScore'] as num?)?.toDouble() ?? 0.0);

    final int totalPages = ((storyData['totalPages'] as num?)?.toInt() ?? 3)
        .clamp(1, 99);

    final int pagesDone = _pageResults().length.clamp(0, totalPages);

    final bool started = storyData.isNotEmpty && pagesDone > 0;

    String status;

    Color statusColor;

    if (isLocked) {
      status = 'Locked';

      statusColor = Colors.black38;
    } else if (completed) {
      status = bestScore >= 50 ? 'Passed' : 'Keep practicing';

      statusColor = bestScore >= 50
          ? const Color(0xFF59A685)
          : const Color(0xFFE3A13B);
    } else if (started) {
      status = '$pagesDone/$totalPages pages';

      statusColor = const Color(0xFF6A5ACD);
    } else {
      status = 'Not started';

      statusColor = Colors.black38;
    }

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        width: R.icon(116),

        padding: EdgeInsets.all(R.space(7)),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(R.radius(16)),

          border: Border.all(
            color: isSelected
                ? const Color(0xFF59A685)
                : Colors.black.withOpacity(0.05),

            width: isSelected ? 1.5 : 1,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF59A685).withOpacity(0.10),

                    blurRadius: 12,

                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),

        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,

                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(R.radius(11)),

                    child: coverPath.isEmpty
                        ? Container(
                            color: const Color(0xFFF1F5F2),

                            child: Icon(
                              Icons.menu_book_rounded,

                              color: const Color(0xFF59A685).withOpacity(0.45),

                              size: R.icon(28),
                            ),
                          )
                        : _ReadingStorageCover(storagePath: coverPath),
                  ),

                  if (isLocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(R.radius(11)),

                      child: Container(color: Colors.white.withOpacity(0.58)),
                    ),

                  if (isLocked)
                    Center(
                      child: Container(
                        width: R.icon(34),

                        height: R.icon(34),

                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),

                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),

                              blurRadius: 6,
                            ),
                          ],
                        ),

                        child: Icon(
                          Icons.lock_rounded,

                          color: const Color(0xFF2D3142).withOpacity(0.55),

                          size: R.icon(17),
                        ),
                      ),
                    ),

                  if (!isLocked && completed)
                    Positioned(
                      top: R.space(5),

                      right: R.space(5),

                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.space(6),

                          vertical: R.space(3),
                        ),

                        decoration: BoxDecoration(
                          color: bestScore >= 50
                              ? const Color(0xFF59A685)
                              : const Color(0xFFE3A13B),

                          borderRadius: BorderRadius.circular(R.radius(10)),
                        ),

                        child: Text(
                          '${bestScore.round()}%',

                          style: GoogleFonts.montserrat(
                            fontSize: R.text(8.5),

                            fontWeight: FontWeight.w700,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  if (!isLocked && !completed && started)
                    Positioned(
                      top: R.space(5),

                      right: R.space(5),

                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: R.space(6),

                          vertical: R.space(3),
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFF6A5ACD),

                          borderRadius: BorderRadius.circular(R.radius(10)),
                        ),

                        child: Text(
                          '$pagesDone/$totalPages',

                          style: GoogleFonts.montserrat(
                            fontSize: R.text(8.5),

                            fontWeight: FontWeight.w700,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: R.space(7)),

            Text(
              title,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              textAlign: TextAlign.center,

              style: GoogleFonts.montserrat(
                fontSize: R.text(9.5),

                fontWeight: FontWeight.w600,

                color: const Color(0xFF2D3142),
              ),
            ),

            SizedBox(height: R.space(2)),

            Text(
              status,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: GoogleFonts.montserrat(
                fontSize: R.text(8.5),

                fontWeight: FontWeight.w500,

                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingStoryDetails extends StatelessWidget {
  final int level;

  final Map<String, dynamic> storyData;

  final bool isLocked;

  final double? previousBestScore;

  const _ReadingStoryDetails({
    required this.level,

    required this.storyData,

    required this.isLocked,

    required this.previousBestScore,
  });

  Map<String, dynamic> _pageResults() {
    final current = Map<String, dynamic>.from(
      storyData['currentPageResults'] ?? {},
    );

    if (current.isNotEmpty) return current;

    return Map<String, dynamic>.from(storyData['pageResults'] ?? {});
  }

  int _value(String key) {
    return ((storyData[key] as num?)?.toInt() ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool completed = storyData['completed'] == true;

    final double bestScore =
        ((storyData['bestScore'] as num?)?.toDouble() ?? 0.0);

    final int completedCount =
        ((storyData['completedCount'] as num?)?.toInt() ?? 0);

    final int totalPages = ((storyData['totalPages'] as num?)?.toInt() ?? 3)
        .clamp(1, 99);

    final Map<String, dynamic> pages = _pageResults();

    final int pagesDone = pages.length.clamp(0, totalPages);

    final bool started = storyData.isNotEmpty && pagesDone > 0;

    if (isLocked) {
      final String previousText = previousBestScore == null
          ? ''
          : ' The previous story best is ${previousBestScore!.round()}%.';

      return Container(
        width: double.infinity,

        padding: EdgeInsets.all(R.space(13)),

        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),

          borderRadius: BorderRadius.circular(R.radius(16)),
        ),

        child: Row(
          children: [
            Container(
              width: R.icon(38),

              height: R.icon(38),

              decoration: BoxDecoration(
                color: Colors.white,

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.lock_outline_rounded,

                color: Colors.black38,

                size: R.icon(19),
              ),
            ),

            SizedBox(width: R.space(10)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Story $level is locked',

                    style: GoogleFonts.montserrat(
                      fontSize: R.text(11.5),

                      fontWeight: FontWeight.w600,

                      color: const Color(0xFF2D3142),
                    ),
                  ),

                  SizedBox(height: R.space(3)),

                  Text(
                    'A best score of 50% or more on Story ${level - 1} unlocks it.$previousText',

                    style: GoogleFonts.montserrat(
                      fontSize: R.text(9.5),

                      fontWeight: FontWeight.w400,

                      color: Colors.black45,

                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!started && !completed) {
      return Container(
        width: double.infinity,

        padding: EdgeInsets.all(R.space(13)),

        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F5),

          borderRadius: BorderRadius.circular(R.radius(16)),
        ),

        child: Row(
          children: [
            Container(
              width: R.icon(38),

              height: R.icon(38),

              decoration: BoxDecoration(
                color: const Color(0xFF59A685).withOpacity(0.12),

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.menu_book_rounded,

                color: const Color(0xFF59A685),

                size: R.icon(20),
              ),
            ),

            SizedBox(width: R.space(10)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Ready to read',

                    style: GoogleFonts.montserrat(
                      fontSize: R.text(11.5),

                      fontWeight: FontWeight.w600,

                      color: const Color(0xFF2D3142),
                    ),
                  ),

                  SizedBox(height: R.space(3)),

                  Text(
                    'This story is unlocked, but no reading result has been saved yet.',

                    style: GoogleFonts.montserrat(
                      fontSize: R.text(9.5),

                      fontWeight: FontWeight.w400,

                      color: Colors.black45,

                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!completed) {
      return Container(
        width: double.infinity,

        padding: EdgeInsets.all(R.space(13)),

        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FC),

          borderRadius: BorderRadius.circular(R.radius(16)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,

                  size: R.icon(17),

                  color: const Color(0xFF6A5ACD),
                ),

                SizedBox(width: R.space(6)),

                Text(
                  'Reading in progress',

                  style: GoogleFonts.montserrat(
                    fontSize: R.text(11.5),

                    fontWeight: FontWeight.w600,

                    color: const Color(0xFF2D3142),
                  ),
                ),

                const Spacer(),

                Text(
                  '$pagesDone/$totalPages pages',

                  style: GoogleFonts.montserrat(
                    fontSize: R.text(10),

                    fontWeight: FontWeight.w600,

                    color: const Color(0xFF6A5ACD),
                  ),
                ),
              ],
            ),

            SizedBox(height: R.space(9)),

            ClipRRect(
              borderRadius: BorderRadius.circular(R.radius(8)),

              child: LinearProgressIndicator(
                value: pagesDone / totalPages,

                minHeight: R.space(6),

                backgroundColor: const Color(0xFFE8E4F8),

                color: const Color(0xFF6A5ACD),
              ),
            ),

            SizedBox(height: R.space(10)),

            _ReadingPageScoreRow(pageResults: pages, totalPages: totalPages),
          ],
        ),
      );
    }

    final int correct = _value('correct');

    final int substitutions = _value('substitutions');

    final int omissions = _value('omissions');

    final int additions = _value('additions');

    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(R.space(13)),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(R.radius(16)),

        border: Border.all(color: const Color(0xFF59A685).withOpacity(0.16)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _ReadingScoreRing(score: bestScore),

              SizedBox(width: R.space(12)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      bestScore >= 50 ? 'Story passed' : 'Keep practicing',

                      style: GoogleFonts.montserrat(
                        fontSize: R.text(12),

                        fontWeight: FontWeight.w600,

                        color: const Color(0xFF2D3142),
                      ),
                    ),

                    SizedBox(height: R.space(3)),

                    Text(
                      bestScore >= 50
                          ? (level < 6
                                ? 'The next story is unlocked.'
                                : 'All reading stories are complete.')
                          : 'A best score of 50% is needed to unlock the next story.',

                      style: GoogleFonts.montserrat(
                        fontSize: R.text(9.5),

                        color: Colors.black45,

                        height: 1.35,
                      ),
                    ),

                    if (completedCount > 0) ...[
                      SizedBox(height: R.space(5)),

                      Text(
                        completedCount == 1
                            ? 'Completed once'
                            : 'Completed $completedCount times',

                        style: GoogleFonts.montserrat(
                          fontSize: R.text(9),

                          fontWeight: FontWeight.w500,

                          color: const Color(0xFF59A685),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: R.space(12)),

          Row(
            children: [
              Expanded(
                child: _ReadingMetric(
                  label: 'Correct',

                  value: correct,

                  icon: Icons.check_circle_rounded,

                  color: const Color(0xFF59A685),

                  background: const Color(0xFFEAF6F0),
                ),
              ),

              SizedBox(width: R.space(7)),

              Expanded(
                child: _ReadingMetric(
                  label: 'Changed',

                  value: substitutions,

                  icon: Icons.swap_horiz_rounded,

                  color: const Color(0xFFF0A24A),

                  background: const Color(0xFFFFF5E8),
                ),
              ),

              SizedBox(width: R.space(7)),

              Expanded(
                child: _ReadingMetric(
                  label: 'Missed',

                  value: omissions,

                  icon: Icons.remove_circle_outline_rounded,

                  color: const Color(0xFFE36E6E),

                  background: const Color(0xFFFFEEEE),
                ),
              ),

              SizedBox(width: R.space(7)),

              Expanded(
                child: _ReadingMetric(
                  label: 'Extra',

                  value: additions,

                  icon: Icons.add_circle_outline_rounded,

                  color: const Color(0xFF7789D8),

                  background: const Color(0xFFEEF1FF),
                ),
              ),
            ],
          ),

          SizedBox(height: R.space(11)),

          _ReadingPageScoreRow(
            pageResults: Map<String, dynamic>.from(
              storyData['pageResults'] ?? pages,
            ),

            totalPages: totalPages,
          ),
        ],
      ),
    );
  }
}

class _ReadingScoreRing extends StatelessWidget {
  final double score;

  const _ReadingScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final double safeScore = score.clamp(0.0, 100.0);

    return SizedBox(
      width: R.icon(66),

      height: R.icon(66),

      child: Stack(
        alignment: Alignment.center,

        children: [
          SizedBox(
            width: R.icon(62),

            height: R.icon(62),

            child: CircularProgressIndicator(
              value: safeScore / 100.0,

              strokeWidth: R.space(6),

              backgroundColor: const Color(0xFF59A685).withOpacity(0.12),

              valueColor: AlwaysStoppedAnimation<Color>(
                safeScore >= 50
                    ? const Color(0xFF59A685)
                    : const Color(0xFFE3A13B),
              ),

              strokeCap: StrokeCap.round,
            ),
          ),

          Text(
            '${safeScore.round()}%',

            style: GoogleFonts.montserrat(
              fontSize: R.text(11),

              fontWeight: FontWeight.w700,

              color: safeScore >= 50
                  ? const Color(0xFF59A685)
                  : const Color(0xFFE3A13B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingMetric extends StatelessWidget {
  final String label;

  final int value;

  final IconData icon;

  final Color color;

  final Color background;

  const _ReadingMetric({
    required this.label,

    required this.value,

    required this.icon,

    required this.color,

    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(5),

        vertical: R.space(8),
      ),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(R.radius(11)),
      ),

      child: Column(
        children: [
          Icon(icon, size: R.icon(15), color: color),

          SizedBox(height: R.space(3)),

          Text(
            '$value',

            style: GoogleFonts.montserrat(
              fontSize: R.text(11),

              fontWeight: FontWeight.w700,

              color: const Color(0xFF2D3142),
            ),
          ),

          SizedBox(height: R.space(1)),

          Text(
            label,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.montserrat(
              fontSize: R.text(7.5),

              fontWeight: FontWeight.w500,

              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingPageScoreRow extends StatelessWidget {
  final Map<String, dynamic> pageResults;

  final int totalPages;

  const _ReadingPageScoreRow({
    required this.pageResults,

    required this.totalPages,
  });

  double? _scoreForPage(int page) {
    final value = pageResults['page_$page'];

    if (value is! Map) return null;

    final data = Map<String, dynamic>.from(value);

    final score = data['pageScore'];

    if (score is num) return score.toDouble();

    return double.tryParse(score?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalPages, (index) {
        final int page = index + 1;

        final double? score = _scoreForPage(page);

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == totalPages - 1 ? 0 : R.space(6),
            ),

            padding: EdgeInsets.symmetric(
              horizontal: R.space(6),

              vertical: R.space(6),
            ),

            decoration: BoxDecoration(
              color: score == null
                  ? const Color(0xFFF5F5F7)
                  : const Color(0xFFF2F8F5),

              borderRadius: BorderRadius.circular(R.radius(9)),
            ),

            child: Column(
              children: [
                Text(
                  'Page $page',

                  style: GoogleFonts.montserrat(
                    fontSize: R.text(7.5),

                    fontWeight: FontWeight.w500,

                    color: Colors.black45,
                  ),
                ),

                SizedBox(height: R.space(2)),

                Text(
                  score == null ? '—' : '${score.round()}%',

                  style: GoogleFonts.montserrat(
                    fontSize: R.text(9.5),

                    fontWeight: FontWeight.w700,

                    color: score == null
                        ? Colors.black26
                        : const Color(0xFF59A685),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ReadingStorageCover extends StatelessWidget {
  final String storagePath;

  const _ReadingStorageCover({required this.storagePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(storagePath).getDownloadURL(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: const Color(0xFFF1F5F2),

            child: Center(
              child: SizedBox(
                width: R.icon(16),

                height: R.icon(16),

                child: const CircularProgressIndicator(
                  strokeWidth: 2,

                  color: Color(0xFF59A685),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            color: const Color(0xFFF1F5F2),

            child: Icon(
              Icons.menu_book_rounded,

              color: const Color(0xFF59A685).withOpacity(0.45),

              size: R.icon(26),
            ),
          );
        }

        return Image.network(
          snapshot.data!,

          fit: BoxFit.cover,

          width: double.infinity,

          height: double.infinity,

          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFF1F5F2),

            child: Icon(
              Icons.menu_book_rounded,

              color: const Color(0xFF59A685).withOpacity(0.45),

              size: R.icon(26),
            ),
          ),
        );
      },
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
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (_) => const AddChildPage()),
                );
              },

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
