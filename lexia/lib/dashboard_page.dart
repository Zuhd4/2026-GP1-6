import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_child_popup.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final double topPad = MediaQuery.of(context).padding.top + 82;
    final double bottomPad = MediaQuery.of(context).padding.bottom + 110;

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final bool hasChild =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            final List<String> childNames = hasChild
                ? snapshot.data!.docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['name'] as String? ?? '').trim();
                      })
                      .where((name) => name.isNotEmpty)
                      .toList()
                : [];

            String childrenText;
            if (childNames.isEmpty) {
              childrenText = "✨ Track your children's learning journey";
            } else if (childNames.length == 1) {
              childrenText = "✨ Track ${childNames.first}'s learning journey";
            } else if (childNames.length == 2) {
              childrenText =
                  "✨ Track ${childNames[0]} and ${childNames[1]}'s learning journey";
            } else {
              childrenText =
                  "✨ Track ${childNames.sublist(0, childNames.length - 1).join(', ')} and ${childNames.last}'s learning journey";
            }

            return Scaffold(
              body: ScrollConfiguration(
                behavior: const _NoStretchBehavior(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, topPad, 20, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello $parentName",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        childrenText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (hasChild)
                        ...snapshot.data!.docs.map(
                          (doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _ChildDashboardCard(doc: doc),
                          ),
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

class _ChildDashboardCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const _ChildDashboardCard({required this.doc});

  @override
  State<_ChildDashboardCard> createState() => _ChildDashboardCardState();
}

class _ChildDashboardCardState extends State<_ChildDashboardCard> {
  late int displayedLevel;
  late int actualLevel;

  final Map<int, List<Map<String, dynamic>>> levelGames = {
    1: [
      {
        'title': 'Letter Scramble',
        'emoji': '🧩',
        'color': const Color(0xFFF1B4AF),
        'score': '1/3',
        'status': 'In Progress',
      },
      {
        'title': 'Word Matching',
        'emoji': '✨',
        'color': const Color(0xFF5B96CA),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Listen and Spell',
        'emoji': '🎧',
        'color': const Color(0xFF59A685),
        'score': '0/3',
        'status': 'Not started',
      },
    ],
    2: [
      {
        'title': 'Letter Scramble',
        'emoji': '🧩',
        'color': const Color(0xFFF1B4AF),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Word Matching',
        'emoji': '✨',
        'color': const Color(0xFF5B96CA),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Listen and Spell',
        'emoji': '🎧',
        'color': const Color(0xFF59A685),
        'score': '0/3',
        'status': 'Not started',
      },
    ],
    3: [
      {
        'title': 'Letter Scramble',
        'emoji': '🧩',
        'color': const Color(0xFFF1B4AF),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Word Matching',
        'emoji': '✨',
        'color': const Color(0xFF5B96CA),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Listen and Spell',
        'emoji': '🎧',
        'color': const Color(0xFF59A685),
        'score': '0/3',
        'status': 'Not started',
      },
    ],
    4: [
      {
        'title': 'Letter Scramble',
        'emoji': '🧩',
        'color': const Color(0xFFF1B4AF),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Word Matching',
        'emoji': '✨',
        'color': const Color(0xFF5B96CA),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Listen and Spell',
        'emoji': '🎧',
        'color': const Color(0xFF59A685),
        'score': '0/3',
        'status': 'Not started',
      },
    ],
    5: [
      {
        'title': 'Letter Scramble',
        'emoji': '🧩',
        'color': const Color(0xFFF1B4AF),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Word Matching',
        'emoji': '✨',
        'color': const Color(0xFF5B96CA),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Listen and Spell',
        'emoji': '🎧',
        'color': const Color(0xFF59A685),
        'score': '0/3',
        'status': 'Not started',
      },
    ],
    6: [
      {
        'title': 'Letter Scramble',
        'emoji': '🧩',
        'color': const Color(0xFFF1B4AF),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Word Matching',
        'emoji': '✨',
        'color': const Color(0xFF5B96CA),
        'score': '0/3',
        'status': 'Not started',
      },
      {
        'title': 'Listen and Spell',
        'emoji': '🎧',
        'color': const Color(0xFF59A685),
        'score': '0/3',
        'status': 'Not started',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    actualLevel = ((data['level'] as num?)?.toInt() ?? 1).clamp(1, 6);
    displayedLevel = actualLevel;
  }

  @override
  void didUpdateWidget(covariant _ChildDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final data = widget.doc.data() as Map<String, dynamic>;
    final newActualLevel = ((data['level'] as num?)?.toInt() ?? 1).clamp(1, 6);

    if (newActualLevel != actualLevel) {
      actualLevel = newActualLevel;
      displayedLevel = actualLevel;
    }
  }

  void nextLevel() {
    if (displayedLevel < 6) {
      setState(() {
        displayedLevel++;
      });
    }
  }

  void previousLevel() {
    if (displayedLevel > 1) {
      setState(() {
        displayedLevel--;
      });
    }
  }

  double calculateLevelProgress(List<Map<String, dynamic>> games) {
    int earned = 0;
    int total = 0;

    for (final game in games) {
      final score = game['score'] as String;
      final parts = score.split('/');
      if (parts.length == 2) {
        earned += int.tryParse(parts[0]) ?? 0;
        total += int.tryParse(parts[1]) ?? 0;
      }
    }

    if (total == 0) return 0;
    return earned / total;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String childName = data['name'] ?? 'Sarah';
    final List<Map<String, dynamic>> currentGames =
        levelGames[displayedLevel] ?? levelGames[1]!;
    final double levelProgress = calculateLevelProgress(currentGames);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFFF3EBFF),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: Color(0xFF6A5ACD),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CHILD PROFILE",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "🏅 Level $actualLevel/6",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A5ACD),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _LevelSection(
              currentLevel: displayedLevel,
              progress: levelProgress,
              onPrevious: previousLevel,
              onNext: nextLevel,
              canGoLeft: displayedLevel > 1,
              canGoRight: displayedLevel < 6,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _GameCard(
                  title: currentGames[0]['title'] as String,
                  emoji: currentGames[0]['emoji'] as String,
                  color: currentGames[0]['color'] as Color,
                  score: currentGames[0]['score'] as String,
                  status: currentGames[0]['status'] as String,
                ),
                const SizedBox(height: 10),
                _GameCard(
                  title: currentGames[1]['title'] as String,
                  emoji: currentGames[1]['emoji'] as String,
                  color: currentGames[1]['color'] as Color,
                  score: currentGames[1]['score'] as String,
                  status: currentGames[1]['status'] as String,
                ),
                const SizedBox(height: 10),
                _GameCard(
                  title: currentGames[2]['title'] as String,
                  emoji: currentGames[2]['emoji'] as String,
                  color: currentGames[2]['color'] as Color,
                  score: currentGames[2]['score'] as String,
                  status: currentGames[2]['status'] as String,
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Stories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  "2/6",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _StoryGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final int currentLevel;
  final double progress;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoLeft;
  final bool canGoRight;

  const _LevelSection({
    required this.currentLevel,
    required this.progress,
    required this.onPrevious,
    required this.onNext,
    required this.canGoLeft,
    required this.canGoRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              "🏅 Level",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF2D3142),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: canGoLeft ? onPrevious : null,
              icon: const Icon(Icons.chevron_left_rounded),
              splashRadius: 20,
              color: canGoLeft ? const Color(0xFF6A5ACD) : Colors.black26,
            ),
            Text(
              "$currentLevel/6",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF2D3142),
              ),
            ),
            IconButton(
              onPressed: canGoRight ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              splashRadius: 20,
              color: canGoRight ? const Color(0xFF6A5ACD) : Colors.black26,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F8),
            color: const Color(0xFF6A5ACD),
          ),
        ),
      ],
    );
  }
}

class _StoryGrid extends StatelessWidget {
  const _StoryGrid();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stories = [
      {
        'name': 'Butterfly Garden',
        'emoji': '🦋',
        'color': const Color(0xFFE8F5E9),
        'done': true,
      },
      {
        'name': 'Sky Adventure',
        'emoji': '✈️',
        'color': const Color(0xFFE3F2FD),
        'done': true,
      },
      {
        'name': 'Magic Stars',
        'emoji': '✨',
        'color': const Color(0xFFF3E5F5),
        'done': false,
      },
      {
        'name': 'Moonlight Dream',
        'emoji': '🌙',
        'color': const Color(0xFFE1F5FE),
        'done': false,
      },
      {
        'name': 'Dragon Friend',
        'emoji': '🐉',
        'color': const Color(0xFFF1F8E9),
        'done': false,
      },
      {
        'name': 'Ocean Friends',
        'emoji': '🐠',
        'color': const Color(0xFFE0F7FA),
        'done': false,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stories.length,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        return _StoryTile(
          name: stories[index]['name'] as String,
          emoji: stories[index]['emoji'] as String,
          color: stories[index]['color'] as Color,
          done: stories[index]['done'] as bool,
        );
      },
    );
  }
}

class _StoryTile extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final bool done;

  const _StoryTile({
    required this.name,
    required this.emoji,
    required this.color,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 34)),
                ),
                if (done)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF59A685),
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String score;
  final String status;
  final Color color;

  const _GameCard({
    required this.title,
    required this.emoji,
    required this.color,
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCDA81).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              score,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.child_care_rounded,
              size: 48,
              color: Color(0xFF6A5ACD),
            ),
            const SizedBox(height: 12),
            const Text(
              "Add a child to get started",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create your child profile to track progress and activities.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddChildPopup(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Add Child",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStretchBehavior extends ScrollBehavior {
  const _NoStretchBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
