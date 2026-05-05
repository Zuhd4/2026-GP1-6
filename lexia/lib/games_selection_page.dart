import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/lexia_popup.dart';
import 'letter_scramble_page.dart';
import 'responsive_helper.dart';

class GamesSelectionPage extends StatefulWidget {
  final int level;
  final String childId;

  const GamesSelectionPage({
    super.key,
    required this.level,
    required this.childId,
  });

  @override
  State<GamesSelectionPage> createState() => _GamesSelectionPageState();
}

class _GamesSelectionPageState extends State<GamesSelectionPage> {
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  static const Color coral = Color.fromARGB(255, 230, 157, 153);
  static const Color blue = Color(0xFF5B96CA);
  static const Color green = Color(0xFF59A685);

  bool letterScrambleCompleted = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>>? get _childRef {
    if (_uid.isEmpty || widget.childId.isEmpty) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('children')
        .doc(widget.childId);
  }

  bool _readLetterScrambleCompleted(Map<String, dynamic>? data) {
    if (data == null) return false;

    final gameProgress = Map<String, dynamic>.from(data['gameProgress'] ?? {});

    final levelKey = 'level_${widget.level}';

    final levelProgress = Map<String, dynamic>.from(
      gameProgress[levelKey] ?? {},
    );

    final letterScramble = Map<String, dynamic>.from(
      levelProgress['letterScramble'] ?? {},
    );

    return letterScramble['completed'] == true;
  }

  int _readLetterScrambleBestStars(Map<String, dynamic>? data) {
    if (data == null) return 0;

    final gameProgress = Map<String, dynamic>.from(data['gameProgress'] ?? {});

    final levelKey = 'level_${widget.level}';

    final levelProgress = Map<String, dynamic>.from(
      gameProgress[levelKey] ?? {},
    );

    final letterScramble = Map<String, dynamic>.from(
      levelProgress['letterScramble'] ?? {},
    );

    return ((letterScramble['bestStars'] as num?)?.toInt() ?? 0).clamp(0, 3);
  }

  void _showComingSoon(BuildContext context) {
    LexiaPopup.showMessage(
      context: context,
      title: "Coming Soon!",
      message: "This feature will be available soon!",
      emoji: "🚀",
      buttonColor: green.withOpacity(0.8),
      buttonText: "Got it!",
    );
  }

  Future<void> _openLetterScramble() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LetterScramblePage(level: widget.level, childId: widget.childId),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        letterScrambleCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final childRef = _childRef;

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(35);
    final double bottomMargin = R.safeBottom + R.space(120);

    if (childRef == null) {
      return const Scaffold(
        backgroundColor: ivoryWhite,
        body: Center(child: Text("Child profile not found")),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: childRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final bool firestoreCompleted = _readLetterScrambleCompleted(data);
        final bool isLetterScrambleCompleted =
            firestoreCompleted || letterScrambleCompleted;

        final int bestStars = _readLetterScrambleBestStars(data);

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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: R.maxContentWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    topMargin,
                    horizontalPad,
                    bottomMargin,
                  ),
                  child: Column(
                    children: [
                      _buildTopBar(context),
                      SizedBox(height: R.space(14)),

                      Text(
                        "Level ${widget.level} Games",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: R.text(29),
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                          height: 1.05,
                        ),
                      ),

                      SizedBox(height: R.space(5)),

                      Text(
                        "Choose a game to practice",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: R.text(12),
                          fontWeight: FontWeight.w500,
                          color: textDark.withOpacity(0.55),
                        ),
                      ),

                      SizedBox(height: R.space(18)),

                      _buildCharacter(),

                      SizedBox(height: R.space(20)),

                      _GameCard(
                        title: "Letter Scramble",
                        subtitle: isLetterScrambleCompleted
                            ? "Completed! Best score: $bestStars/3 stars."
                            : "Arrange the letters to form the correct word.",
                        emoji: "🧩",
                        color: coral,
                        isLarge: true,
                        buttonText: isLetterScrambleCompleted
                            ? "Completed"
                            : "Play",
                        isCompleted: isLetterScrambleCompleted,
                        onTap: _openLetterScramble,
                      ),

                      SizedBox(height: R.space(14)),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool veryNarrow = constraints.maxWidth < 330;

                          if (veryNarrow) {
                            return Column(
                              children: [
                                _GameCard(
                                  title: "Listen and Spell",
                                  subtitle:
                                      "Listen carefully and spell the word.",
                                  emoji: "🎧",
                                  color: green,
                                  buttonText: "Coming soon",
                                  isLocked: true,
                                  onTap: () => _showComingSoon(context),
                                ),
                                SizedBox(height: R.space(12)),
                                _GameCard(
                                  title: "Word Matching",
                                  subtitle: "Match the word with the picture.",
                                  emoji: "✨",
                                  color: blue,
                                  buttonText: "Coming soon",
                                  isLocked: true,
                                  onTap: () => _showComingSoon(context),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _GameCard(
                                  title: "Listen\nand Spell",
                                  subtitle:
                                      "Listen carefully and spell the word.",
                                  emoji: "🎧",
                                  color: green,
                                  buttonText: "Play",
                                  isLocked: true,
                                  onTap: () => _showComingSoon(context),
                                ),
                              ),
                              SizedBox(width: R.space(12)),
                              Expanded(
                                child: _GameCard(
                                  title: "Word\nMatching",
                                  subtitle: "Match the word with the picture.",
                                  emoji: "✨",
                                  color: blue,
                                  buttonText: "Play",
                                  isLocked: true,
                                  onTap: () => _showComingSoon(context),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: textDark,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              "Level ${widget.level} Games",
              style: GoogleFonts.montserrat(
                fontSize: R.text(18),
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildCharacter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: R.space(12)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(R.radius(26)),
      ),
      child: Image.asset(
        "assets/e_happy.png",
        height: R.space(105),
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
  final bool isCompleted;
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
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isLarge ? R.space(16) : R.space(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF59A685)
                    : color.withOpacity(0.12),
                width: isCompleted ? 1.4 : 1,
              ),
            ),
            child: isLarge ? _largeLayout() : _smallLayout(),
          ),
          if (isCompleted)
            Positioned(
              top: R.space(10),
              right: R.space(10),
              child: Container(
                width: R.icon(28),
                height: R.icon(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF59A685),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF59A685).withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: R.icon(18),
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _largeLayout() {
    return Row(
      children: [
        _iconBox(58),
        SizedBox(width: R.space(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleText(fontSize: 20),
              SizedBox(height: R.space(5)),
              _subtitleText(),
              SizedBox(height: R.space(12)),
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
        _iconBox(46),
        SizedBox(height: R.space(8)),
        _titleText(fontSize: 16, center: true),
        SizedBox(height: R.space(6)),
        _subtitleText(center: true),
        SizedBox(height: R.space(12)),
        _button(),
      ],
    );
  }

  Widget _iconBox(double size) {
    return Container(
      width: R.icon(size),
      height: R.icon(size),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(R.radius(16)),
      ),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: isLocked ? 0.3 : 1.0,
              child: Text(
                emoji,
                style: TextStyle(fontSize: R.text(size * 0.40)),
              ),
            ),
          ),
          if (isLocked)
            Center(
              child: Icon(
                Icons.lock_outline_rounded,
                color: const Color(0xFF2D3142).withOpacity(0.4),
                size: R.icon(24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titleText({required double fontSize, bool center = false}) {
    return Text(
      title,
      textAlign: center ? TextAlign.center : TextAlign.start,
      maxLines: isLarge ? 2 : 3,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.fredoka(
        fontSize: R.text(fontSize),
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
        fontSize: isLarge ? R.text(11.5) : R.text(10),
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: const Color(0xFF2D3142).withOpacity(0.55),
      ),
    );
  }

  Widget _button() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isLarge ? R.space(10) : R.space(8),
      ),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.shade300
            : isCompleted
            ? const Color(0xFF59A685)
            : color,
        borderRadius: BorderRadius.circular(R.radius(15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCompleted) ...[
            Icon(
              Icons.replay_rounded,
              size: isLarge ? R.icon(17) : R.icon(14),
              color: Colors.white,
            ),
            SizedBox(width: R.space(6)),
          ],
          Flexible(
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: isLarge ? R.text(12.5) : R.text(10),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
