import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LetterScramblePage extends StatefulWidget {
  final int level;

  const LetterScramblePage({super.key, required this.level});

  @override
  State<LetterScramblePage> createState() => _LetterScramblePageState();
}

class _LetterScramblePageState extends State<LetterScramblePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);
  static const Color coral = Color(0xFFF1B4AF);

  String targetWord = "";
  List<String> scrambledLetters = [];
  List<String> selectedLetters = [];

  bool isLoading = true;
  bool isChecking = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNewWord();
  }

  List<String> _buildScrambledLetters(String word) {
    final letters = word.split('');

    if (letters.length <= 1) return letters;

    final original = word;
    final shuffled = List<String>.from(letters);

    int attempts = 0;
    do {
      shuffled.shuffle();
      attempts++;
    } while (shuffled.join() == original && attempts < 10);

    return shuffled;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchWordFromFirestore({
    required double randomValue,
  }) async {
    const collectionName = 'vocabulary_test';

    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: 'done')
        .where('validation_status', isEqualTo: 'done')
        .where('is_safe', isEqualTo: true)
        .where('is_educational', isEqualTo: true)
        .where('is_representable', isEqualTo: true)
        .where('level', isEqualTo: widget.level)
        .orderBy('shuffle_key')
        .startAt([randomValue])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      snapshot = await _firestore
          .collection(collectionName)
          .where('status', isEqualTo: 'done')
          .where('validation_status', isEqualTo: 'done')
          .where('is_safe', isEqualTo: true)
          .where('is_educational', isEqualTo: true)
          .where('is_representable', isEqualTo: true)
          .where('level', isEqualTo: widget.level)
          .orderBy('shuffle_key')
          .limit(1)
          .get();
    }

    return snapshot;
  }

  Future<void> loadNewWord() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isChecking = false;
      errorMessage = null;
      selectedLetters.clear();
      scrambledLetters.clear();
      targetWord = "";
    });

    try {
      final randomValue = _random.nextDouble();
      final snapshot = await _fetchWordFromFirestore(randomValue: randomValue);

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          errorMessage = "No words found for this level.";
          isLoading = false;
        });
        return;
      }

      final data = snapshot.docs.first.data();
      final fetchedWord = (data['word'] ?? '').toString().trim().toLowerCase();

      if (fetchedWord.isEmpty) {
        if (!mounted) return;
        setState(() {
          errorMessage = "The fetched word is empty.";
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        targetWord = fetchedWord;
        scrambledLetters = _buildScrambledLetters(targetWord);
        selectedLetters = [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load word: $e";
        isLoading = false;
      });
    }
  }

  void onLetterTap(int index) {
    if (isLoading || isChecking) return;
    if (index < 0 || index >= scrambledLetters.length) return;
    if (scrambledLetters[index].isEmpty) return;
    if (selectedLetters.length >= targetWord.length) return;

    setState(() {
      selectedLetters.add(scrambledLetters[index]);
      scrambledLetters[index] = "";
    });
  }

  void removeLastLetter() {
    if (isLoading || isChecking) return;
    if (selectedLetters.isEmpty) return;

    setState(() {
      final lastLetter = selectedLetters.removeLast();
      final emptyIndex = scrambledLetters.indexOf("");
      if (emptyIndex != -1) {
        scrambledLetters[emptyIndex] = lastLetter;
      }
    });
  }

  void resetWord() {
    if (isLoading || isChecking) return;
    if (targetWord.isEmpty) return;

    setState(() {
      selectedLetters.clear();
      scrambledLetters = _buildScrambledLetters(targetWord);
    });
  }

  Future<void> checkAnswer() async {
    if (targetWord.isEmpty || isChecking || isLoading) return;

    final userAnswer = selectedLetters.join();

    if (userAnswer.length != targetWord.length) {
      await _showMessage(
        text: "Complete the word first",
        imagePath: "assets/e_think.png",
      );
      return;
    }

    setState(() {
      isChecking = true;
    });

    if (userAnswer == targetWord) {
      await _showMessage(text: "Well done!", imagePath: "assets/e_wink.png");
      await loadNewWord();
    } else {
      await _showMessage(text: "Try again", imagePath: "assets/e_think.png");

      if (!mounted) return;
      setState(() {
        selectedLetters.clear();
        scrambledLetters = _buildScrambledLetters(targetWord);
        isChecking = false;
      });
    }
  }

  String get currentAnswer {
    if (targetWord.isEmpty) return "";

    final display = List<String>.filled(targetWord.length, "_");
    for (int i = 0; i < selectedLetters.length && i < display.length; i++) {
      display[i] = selectedLetters[i];
    }
    return display.join(" ");
  }

  Future<void> _showMessage({
    required String text,
    required String imagePath,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      imagePath,
                      height: 115,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            color: softCream,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryPurple.withOpacity(0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: primaryPurple.withOpacity(0.35),
                            size: 42,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green.withOpacity(0.85),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Got it",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          "Letter Scramble",
          style: GoogleFonts.fredoka(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryPurple),
                  )
                : errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildQuestionCard(),
                      const SizedBox(height: 26),
                      _buildLetters(),
                      const SizedBox(height: 28),
                      _buildActionButtons(),
                      const Spacer(),
                      _buildCheckButton(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loadNewWord,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "Try Again",
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image holder مؤقت
          Container(
            width: double.infinity,
            height: 145,
            decoration: BoxDecoration(
              color: softCream,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primaryPurple.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_rounded,
                  size: 46,
                  color: primaryPurple.withOpacity(0.35),
                ),
                const SizedBox(height: 8),
                Text(
                  "Image will appear here",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textDark.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "Arrange the letters to form the correct word",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                currentAnswer,
                style: GoogleFonts.fredoka(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: primaryPurple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(scrambledLetters.length, (index) {
        final letter = scrambledLetters[index];

        return GestureDetector(
          onTap: () => onLetterTap(index),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: letter.isEmpty
                  ? Colors.white.withOpacity(0.65)
                  : primaryPurple,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: letter.isEmpty
                    ? primaryPurple.withOpacity(0.08)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: letter.isEmpty ? Colors.transparent : Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: removeLastLetter,
                icon: const Icon(Icons.backspace_outlined, size: 20),
                label: Text(
                  "Delete",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD94B43),
                  disabledBackgroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFFD94B43),
                  overlayColor: Colors.black.withOpacity(0.03),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: resetWord,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  "Reset",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color.fromRGBO(106, 90, 205, 1),
                  elevation: 0,
                  overlayColor: Colors.black.withOpacity(0.03),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          "Check Answer",
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
