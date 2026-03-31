import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_child_popup.dart';

// ── Lexia Brand Palette ──────────────────────────────────────────────────────
class LexiaColors {
  static const Color bg = Color(0xFFFDF8F4);          // warm parchment
  static const Color blue = Color(0xFF5B96CA);         // L – sky blue
  static const Color peach = Color(0xFFF1B4AF);        // E – soft peach
  static const Color green = Color(0xFF59A685);        // X – mint green
  static const Color yellow = Color(0xFFFCDA81);       // I – sunshine yellow
  static const Color purple = Color(0xFFD8BDD9);       // A – lavender
  static const Color pink = Color(0xFFFF5695);         // cheek accent
  static const Color dark = Color(0xFF2D3142);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFF3F4F8);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: LexiaColors.bg,
            body: Center(
              child: CircularProgressIndicator(color: LexiaColors.blue),
            ),
          );
        }

        final bool hasChild =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        final String parentName =
            (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty ??
                    false)
                ? FirebaseAuth.instance.currentUser!.displayName!.trim()
                : 'Parent';

        if (hasChild) {
          final childrenDocs = snapshot.data!.docs;

          return Container(
            color: LexiaColors.bg,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    _DashboardHeader(parentName: parentName),
                    const SizedBox(height: 24),

                    // ── Child cards ─────────────────────────────────────────
                    ...childrenDocs.map((doc) {
                      final childData =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final String childName =
                          (childData['name'] ??
                                  childData['childName'] ??
                                  'Child Name')
                              .toString();
                      final String childImage =
                          (childData['imageUrl'] ?? childData['photoUrl'] ?? '')
                              .toString();

                      final List<Map<String, dynamic>> games = [
                        {
                          'title': 'Letter Scramble',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.extension_rounded,
                          'color': LexiaColors.peach,
                          'emoji': '🧩',
                        },
                        {
                          'title': 'Word Matching',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.auto_awesome_motion_rounded,
                          'color': LexiaColors.blue,
                          'emoji': '✨',
                        },
                        {
                          'title': 'Listen and Spell',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.volume_up_rounded,
                          'color': LexiaColors.green,
                          'emoji': '🎧',
                        },
                        {
                          'title': 'Story',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.menu_book_rounded,
                          'color': LexiaColors.yellow,
                          'emoji': '📖',
                        },
                      ];

                      const double progress = 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _ChildDashboardCard(
                          childName: childName,
                          childImage: childImage,
                          progress: progress,
                          games: games,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        }

        // ── Empty state ──────────────────────────────────────────────────────
        return Container(
          color: LexiaColors.bg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _EmptyStateCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Dashboard Header ──────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final String parentName;
  const _DashboardHeader({required this.parentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B96CA), Color(0xFF7BB3D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: LexiaColors.blue.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Decorative bubbles + text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Hello, $parentName!",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text("👋", style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Track your children's learning journey ✨",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _LetterBubble extends StatelessWidget {
  final String letter;
  final Color color;
  const _LetterBubble(this.letter, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: LexiaColors.dark,
          ),
        ),
      ),
    );
  }
}

// ── Child Dashboard Card ──────────────────────────────────────────────────────
class _ChildDashboardCard extends StatelessWidget {
  final String childName;
  final String childImage;
  final double progress;
  final List<Map<String, dynamic>> games;

  const _ChildDashboardCard({
    required this.childName,
    required this.childImage,
    required this.progress,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: LexiaColors.cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: LexiaColors.blue.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: LexiaColors.purple.withOpacity(0.35),
          width: 1.8,
        ),
      ),
      child: Column(
        children: [
          // ── Coloured top banner ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3EBFF), Color(0xFFE8F4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [LexiaColors.peach, LexiaColors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: LexiaColors.pink.withOpacity(0.20),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image: childImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(childImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: childImage.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: LexiaColors.blue,
                                )
                              : null,
                        ),
                      ),
                    ),
                    // Star badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: LexiaColors.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child:
                              Text("⭐", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Child Profile",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: LexiaColors.dark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Level chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: LexiaColors.purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "🏅  Level 0",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: LexiaColors.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Progress section ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: _ProgressSection(progress: progress),
          ),

          // ── Game cards ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: games
                  .map(
                    (game) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GameCard(
                        title: game['title'],
                        status: game['status'],
                        score: game['score'],
                        icon: game['icon'],
                        emoji: game['emoji'],
                        accentColor: game['color'],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Section ──────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final double progress;
  const _ProgressSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LexiaColors.softGrey,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text("🚀 ", style: TextStyle(fontSize: 16)),
                  Text(
                    "Overall Progress",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: LexiaColors.dark,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LexiaColors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "0%",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: LexiaColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented rainbow progress bar (4 game segments)
          Row(
            children: [
              _ProgressSegment(LexiaColors.peach, progress, isFirst: true),
              const SizedBox(width: 4),
              _ProgressSegment(LexiaColors.blue, progress),
              const SizedBox(width: 4),
              _ProgressSegment(LexiaColors.green, progress),
              const SizedBox(width: 4),
              _ProgressSegment(LexiaColors.yellow, progress, isLast: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final Color color;
  final double progress;
  final bool isFirst;
  final bool isLast;
  const _ProgressSegment(this.color, this.progress,
      {this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(30) : Radius.zero,
          right: isLast ? const Radius.circular(30) : Radius.zero,
        ),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 14,
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

// ── Game Card ─────────────────────────────────────────────────────────────────
class _GameCard extends StatelessWidget {
  final String title;
  final String status;
  final String score;
  final IconData icon;
  final String emoji;
  final Color accentColor;

  const _GameCard({
    required this.title,
    required this.status,
    required this.score,
    required this.icon,
    required this.emoji,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.30),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon bubble
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LexiaColors.dark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: status,
                      bg: accentColor.withOpacity(0.18),
                      textColor: LexiaColors.dark,
                    ),
                    _Chip(
                      label: "⭐ $score",
                      bg: LexiaColors.yellow.withOpacity(0.25),
                      textColor: LexiaColors.dark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Arrow hint
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: accentColor.withOpacity(0.80),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _Chip(
      {required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Empty State Card ──────────────────────────────────────────────────────────
class _EmptyStateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: LexiaColors.blue.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: LexiaColors.purple.withOpacity(0.35),
          width: 1.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked letter bubbles decoration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BigLetterBubble("L", LexiaColors.blue),
              const SizedBox(width: 8),
              _BigLetterBubble("E", LexiaColors.peach),
              const SizedBox(width: 8),
              _BigLetterBubble("X", LexiaColors.green),
              const SizedBox(width: 8),
              _BigLetterBubble("I", LexiaColors.yellow),
              const SizedBox(width: 8),
              _BigLetterBubble("A", LexiaColors.purple),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LexiaColors.blue, LexiaColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: LexiaColors.blue.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Child Account Yet",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: LexiaColors.dark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Add a child to start tracking their progress and sending them books.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 230,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddChildPopup(),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text(
                "Add Child Account",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LexiaColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigLetterBubble extends StatelessWidget {
  final String letter;
  final Color color;
  const _BigLetterBubble(this.letter, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}