import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_child_popup.dart';

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
          return const Center(child: CircularProgressIndicator());
        }

        final bool hasChild =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        const Color pageBg = Color(0xFFF9F7F4);
        const Color primaryBlue = Color(0xFF5B96CA);
        const Color primaryGreen = Color(0xFF59A685);
        const Color softPeach = Color(0xFFF1B4AF);
        const Color softYellow = Color(0xFFFCDA81);
        const Color softPurple = Color(0xFFD8BDD9);
        const Color accentPink = Color(0xFFFF5695);
        const Color softGrey = Color(0xFFF1F2F4);
        const Color textDark = Color(0xFF2D3142);

        final String parentName =
            (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty ??
                    false)
                ? FirebaseAuth.instance.currentUser!.displayName!.trim()
                : 'Parent';

        if (hasChild) {
          final childrenDocs = snapshot.data!.docs;

          return Container(
            color: pageBg,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $parentName 👋",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Here’s your children’s learning progress.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    ...childrenDocs.map((doc) {
                      final childData = doc.data() as Map<String, dynamic>? ?? {};

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
                          'color': softPeach,
                        },
                        {
                          'title': 'Word Matching',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.auto_awesome_motion_rounded,
                          'color': primaryBlue,
                        },
                        {
                          'title': 'Listen and Spell',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.volume_up_rounded,
                          'color': primaryGreen,
                        },
                        {
                          'title': 'Story',
                          'status': 'Not started',
                          'score': '0/3',
                          'icon': Icons.menu_book_rounded,
                          'color': softYellow,
                        },
                      ];

                      const double progress = 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _ChildDashboardCard(
                          childName: childName,
                          childImage: childImage,
                          progress: progress,
                          games: games,
                          primaryBlue: primaryBlue,
                          primaryGreen: primaryGreen,
                          softPurple: softPurple,
                          softGrey: softGrey,
                          softPeach: softPeach,
                          accentPink: accentPink,
                          textDark: textDark,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          color: pageBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.12),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5B96CA),
                              Color(0xFFD8BDD9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "No Child Account Yet",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Add a child to start tracking their progress and sending them books.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddChildPopup(),
                            );
                          },
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            "Add Child Account",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChildDashboardCard extends StatelessWidget {
  final String childName;
  final String childImage;
  final double progress;
  final List<Map<String, dynamic>> games;
  final Color primaryBlue;
  final Color primaryGreen;
  final Color softPurple;
  final Color softGrey;
  final Color softPeach;
  final Color accentPink;
  final Color textDark;

  const _ChildDashboardCard({
    required this.childName,
    required this.childImage,
    required this.progress,
    required this.games,
    required this.primaryBlue,
    required this.primaryGreen,
    required this.softPurple,
    required this.softGrey,
    required this.softPeach,
    required this.accentPink,
    required this.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8FBFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: primaryBlue.withOpacity(0.12),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [softPeach, softPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentPink.withOpacity(0.12),
                      blurRadius: 12,
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
                        ? Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: primaryBlue,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Child Profile",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      childName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: softPurple.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Level 0",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softGrey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Overall Progress",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    Text(
                      "0%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...games.map(
            (game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GameCard(
                title: game['title'],
                status: game['status'],
                score: game['score'],
                icon: game['icon'],
                accentColor: game['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String status;
  final String score;
  final IconData icon;
  final Color accentColor;

  const _GameCard({
    required this.title,
    required this.status,
    required this.score,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF2D3142);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: textDark,
              size: 28,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        score,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}