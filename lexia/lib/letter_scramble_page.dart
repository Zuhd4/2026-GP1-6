import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/lexia_popup.dart';
import 'level_complete_page.dart';
import 'responsive_helper.dart';

class LetterScramblePage extends StatefulWidget {
  final int level;
  final String childId;

  const LetterScramblePage({
    super.key,
    required this.level,
    required this.childId,
  });

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

  final int totalWordsPerRound = 3;
  final int maxAttemptsPerWord = 3;
  final int requiredCorrectToPass = 2;

  List<Map<String, String>> roundWords = [];
  Set<String> previousRoundWords = {};

  int currentWordIndex = 0;
  int attemptsForCurrentWord = 0;
  int stars = 0;
  int correctWithoutHelp = 0;

  String targetWord = "";
  String currentImageUrl = "";

  List<String> scrambledLetters = [];
  List<String> selectedLetters = [];

  bool isLoading = true;
  bool isChecking = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNewRound();
  }

  List<String> _buildScrambledLetters(String word) {
    final letters = word.replaceAll(' ', '').split('');
    if (letters.length <= 1) return letters;

    final shuffled = List<String>.from(letters);
    int attempts = 0;

    do {
      shuffled.shuffle();
      attempts++;
    } while (shuffled.join() == word.replaceAll(' ', '') && attempts < 10);

    return shuffled;
  }

  Future<List<Map<String, String>>> _fetchRoundWords() async {
    const collectionName = 'vocabulary_test';
    final randomValue = _random.nextDouble();

    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: 'done')
        .where('validation_status', isEqualTo: 'done')
        .where('image_status', isEqualTo: 'done')
        .where('image_validation_status', isEqualTo: 'done')
        .where('is_safe', isEqualTo: true)
        .where('is_educational', isEqualTo: true)
        .where('is_representable', isEqualTo: true)
        .where('level', isEqualTo: widget.level)
        .orderBy('shuffle_key')
        .startAt([randomValue])
        .limit(30)
        .get();

    if (snapshot.docs.length < totalWordsPerRound) {
      snapshot = await _firestore
          .collection(collectionName)
          .where('status', isEqualTo: 'done')
          .where('validation_status', isEqualTo: 'done')
          .where('image_status', isEqualTo: 'done')
          .where('image_validation_status', isEqualTo: 'done')
          .where('is_safe', isEqualTo: true)
          .where('is_educational', isEqualTo: true)
          .where('is_representable', isEqualTo: true)
          .where('level', isEqualTo: widget.level)
          .orderBy('shuffle_key')
          .limit(30)
          .get();
    }

    final words = snapshot.docs
        .map((doc) {
          final data = doc.data();

          final word = (data['word'] ?? '').toString().trim().toLowerCase();

          final imageUrl =
              (data['image_url'] ?? data['imageUrl'] ?? data['image'] ?? '')
                  .toString()
                  .trim();

          return {'word': word, 'imageUrl': imageUrl};
        })
        .where((item) {
          final word = item['word'] ?? '';
          return word.isNotEmpty && !previousRoundWords.contains(word);
        })
        .toList();

    words.shuffle();

    return words.take(totalWordsPerRound).toList();
  }

  Future<void> loadNewRound() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isChecking = false;
      errorMessage = null;

      roundWords.clear();
      currentWordIndex = 0;
      attemptsForCurrentWord = 0;
      stars = 0;
      correctWithoutHelp = 0;

      targetWord = "";
      currentImageUrl = "";
      selectedLetters.clear();
      scrambledLetters.clear();
    });

    try {
      final fetchedWords = await _fetchRoundWords();

      if (fetchedWords.length < totalWordsPerRound) {
        if (!mounted) return;
        setState(() {
          errorMessage =
              "Not enough new words found for this level. Please add more words.";
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        roundWords = fetchedWords;
        _loadCurrentWord();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load words: $e";
        isLoading = false;
      });
    }
  }

  void _loadCurrentWord() {
    final current = roundWords[currentWordIndex];

    targetWord = current['word'] ?? '';
    currentImageUrl = current['imageUrl'] ?? '';

    attemptsForCurrentWord = 0;
    selectedLetters = [];
    scrambledLetters = _buildScrambledLetters(targetWord);
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
    final correctAnswer = targetWord.replaceAll(' ', '');

    if (userAnswer.length != correctAnswer.length) {
      await _showSimpleDialog(
        title: "Complete the word first",
        message: "Arrange all letters before checking.",
        icon: Icons.edit_rounded,
        iconColor: primaryPurple,
      );
      return;
    }

    setState(() {
      isChecking = true;
    });

    if (userAnswer == correctAnswer) {
      stars++;
      correctWithoutHelp++;

      await _showStarDialog();
      await _goToNextWordOrFinishRound();
    } else {
      attemptsForCurrentWord++;

      if (attemptsForCurrentWord >= maxAttemptsPerWord) {
        await _showSimpleDialog(
          title: "Good try!",
          message: "The correct answer is: $targetWord",
          icon: Icons.lightbulb_rounded,
          iconColor: Colors.amber,
        );

        await _goToNextWordOrFinishRound();
      } else {
        await _showSimpleDialog(
          title: "Try again",
          message:
              "You have ${maxAttemptsPerWord - attemptsForCurrentWord} attempt(s) left.",
          icon: Icons.refresh_rounded,
          iconColor: primaryPurple,
        );

        if (!mounted) return;
        setState(() {
          selectedLetters.clear();
          scrambledLetters = _buildScrambledLetters(targetWord);
          isChecking = false;
        });
      }
    }
  }

  Future<void> _goToNextWordOrFinishRound() async {
    if (!mounted) return;

    if (currentWordIndex < totalWordsPerRound - 1) {
      setState(() {
        currentWordIndex++;
        _loadCurrentWord();
        isChecking = false;
      });
    } else {
      previousRoundWords = roundWords
          .map((item) => item['word'] ?? '')
          .where((word) => word.isNotEmpty)
          .toSet();

      await _finishRound();
    }
  }

  Future<void> _saveLetterScrambleProgress() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    debugPrint("SAVE START");
    debugPrint("uid = $uid");
    debugPrint("childId = ${widget.childId}");
    debugPrint("level = ${widget.level}");
    debugPrint("stars = $stars");
    debugPrint("correctWithoutHelp = $correctWithoutHelp");

    if (uid.isEmpty || widget.childId.isEmpty) {
      debugPrint("SAVE STOPPED: uid or childId is empty");
      return;
    }

    final DocumentReference<Map<String, dynamic>> childRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc(widget.childId);

    final String levelKey = 'level_${widget.level}';

    final DocumentSnapshot<Map<String, dynamic>> doc = await childRef.get();
    final Map<String, dynamic>? data = doc.data();

    final Map<String, dynamic> currentProgress = Map<String, dynamic>.from(
      data?['gameProgress'] ?? {},
    );

    final Map<String, dynamic> currentLevelProgress = Map<String, dynamic>.from(
      currentProgress[levelKey] ?? {},
    );

    final Map<String, dynamic> oldLetterScramble = Map<String, dynamic>.from(
      currentLevelProgress['letterScramble'] ?? {},
    );

    final int oldBestStars =
        ((oldLetterScramble['bestStars'] as num?)?.toInt() ?? 0);

    final int oldCompletedCount =
        ((oldLetterScramble['completedCount'] as num?)?.toInt() ?? 0);

    final int newBestStars = stars > oldBestStars ? stars : oldBestStars;

    currentLevelProgress['letterScramble'] = {
      'completed': true,
      'completedCount': oldCompletedCount + 1,
      'stars': stars,
      'bestStars': newBestStars,
      'lastScore': correctWithoutHelp,
      'totalWords': totalWordsPerRound,
      'passedAt': FieldValue.serverTimestamp(),
    };

    currentLevelProgress['updatedAt'] = FieldValue.serverTimestamp();
    currentProgress[levelKey] = currentLevelProgress;

    await childRef.set({
      'gameProgress': currentProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint("SAVE DONE");
  }

  Future<void> _finishRound() async {
    final passed = correctWithoutHelp >= requiredCorrectToPass;

    if (passed) {
      if (!mounted) return;

      try {
        await _saveLetterScrambleProgress();
      } catch (e) {
        debugPrint("Failed to save Letter Scramble progress: $e");
      }

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LevelCompletePage(
            stars: stars,
            level: widget.level,
            childId: widget.childId,
          ),
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, result ?? true);
    } else {
      await _showSimpleDialog(
        title: "Try again",
        message:
            "You got $correctWithoutHelp/3 correct without help. You need at least 2/3 to unlock the next level.",
        icon: Icons.lock_outline_rounded,
        iconColor: primaryPurple,
      );

      await loadNewRound();
    }
  }

  String get currentAnswer {
    if (targetWord.isEmpty) return "";

    int selectedIndex = 0;
    final List<String> display = [];

    for (int i = 0; i < targetWord.length; i++) {
      if (targetWord[i] == ' ') {
        display.add('   ');
      } else {
        if (selectedIndex < selectedLetters.length) {
          display.add(selectedLetters[selectedIndex]);
          selectedIndex++;
        } else {
          display.add('_');
        }
      }
    }

    return display.join(' ');
  }

  Future<void> _showStarDialog() async {
    if (!mounted) return;

    await LexiaPopup.showMessage(
      context: context,
      title: "Awesome!",
      message: "You earned a star",
      icon: Icons.star_rounded,
      iconColor: Colors.amber,
      buttonColor: green,
      buttonText: "Nice!",
      barrierDismissible: false,
    );
  }

  Future<void> _showSimpleDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) async {
    if (!mounted) return;

    await LexiaPopup.showMessage(
      context: context,
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      buttonColor: green,
      buttonText: "Got it",
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: R.pagePad,
                  vertical: R.space(10),
                ),
                child: _buildHeader(context),
              ),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryPurple),
                      )
                    : errorMessage != null
                    ? Padding(
                        padding: EdgeInsets.all(R.space(20)),
                        child: _buildErrorState(),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: R.maxContentWidth,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              R.pagePad,
                              R.space(14),
                              R.pagePad,
                              R.safeBottom + R.space(24),
                            ),
                            child: Column(
                              children: [
                                _buildProgressHeader(),
                                SizedBox(height: R.space(14)),
                                _buildQuestionCard(),
                                SizedBox(height: R.space(18)),
                                _buildLetters(),
                                SizedBox(height: R.space(18)),
                                _buildActionButtons(),
                                SizedBox(height: R.space(16)),
                                _buildCheckButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: R.icon(40),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: R.icon(20),
              color: textDark,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              "Letter Scramble",
              style: GoogleFonts.montserrat(
                fontSize: R.text(18),
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
          ),
        ),
        SizedBox(width: R.icon(40)),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Word ${currentWordIndex + 1}/$totalWordsPerRound",
          style: GoogleFonts.montserrat(
            fontSize: R.text(17),
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        Row(
          children: List.generate(3, (index) {
            return Icon(
              index < stars ? Icons.star_rounded : Icons.star_border_rounded,
              color: index < stars ? Colors.amber : textDark.withOpacity(0.25),
              size: R.icon(28),
            );
          }),
        ),
      ],
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
              fontSize: R.text(15),
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
          ),
          SizedBox(height: R.space(16)),
          ElevatedButton(
            onPressed: loadNewRound,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.radius(16)),
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
      padding: EdgeInsets.all(R.space(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRoundedImageFrame(),
          SizedBox(height: R.space(16)),
          Text(
            "Arrange the letters to form the correct word",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: R.text(15.5),
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: R.space(8)),
          Text(
            "Attempt ${attemptsForCurrentWord + 1}/$maxAttemptsPerWord",
            style: GoogleFonts.montserrat(
              fontSize: R.text(12),
              fontWeight: FontWeight.w500,
              color: textDark.withOpacity(0.38),
            ),
          ),
          SizedBox(height: R.space(16)),
          FractionallySizedBox(
            widthFactor: 0.82,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: R.space(10),
                vertical: R.space(10),
              ),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(R.radius(16)),
              ),
              child: Center(
                child: Text(
                  currentAnswer,
                  style: GoogleFonts.fredoka(
                    fontSize: R.text(15),
                    fontWeight: FontWeight.bold,
                    letterSpacing: R.space(1.5),
                    color: primaryPurple,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedImageFrame() {
    return Center(
      child: Container(
        width: R.icon(150),
        height: R.icon(150),
        padding: EdgeInsets.all(R.space(7)),
        decoration: BoxDecoration(
          color: softCream,
          borderRadius: BorderRadius.circular(R.radius(30)),
          border: Border.all(
            color: primaryPurple.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(R.radius(24)),
          child: Container(
            color: Colors.white.withOpacity(0.65),
            child: currentImageUrl.isNotEmpty
                ? Image.network(
                    currentImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.image_rounded,
        size: R.icon(42),
        color: primaryPurple.withOpacity(0.35),
      ),
    );
  }

  Widget _buildLetters() {
    return Wrap(
      spacing: R.space(10),
      runSpacing: R.space(10),
      alignment: WrapAlignment.center,
      children: List.generate(scrambledLetters.length, (index) {
        final letter = scrambledLetters[index];

        return GestureDetector(
          onTap: () => onLetterTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: R.icon(44),
            height: R.icon(44),
            decoration: BoxDecoration(
              color: letter.isEmpty
                  ? Colors.white.withOpacity(0.65)
                  : primaryPurple,
              borderRadius: BorderRadius.circular(R.radius(16)),
              border: Border.all(
                color: letter.isEmpty
                    ? primaryPurple.withOpacity(0.08)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.fredoka(
                  fontSize: R.text(18),
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
          child: SizedBox(
            height: R.buttonH(52),
            child: ElevatedButton.icon(
              onPressed: removeLastLetter,
              icon: Icon(Icons.backspace_outlined, size: R.icon(19)),
              label: Text(
                "Delete",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: R.text(14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD94B43),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(17)),
                  side: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: R.space(10)),
        Expanded(
          child: SizedBox(
            height: R.buttonH(52),
            child: ElevatedButton.icon(
              onPressed: resetWord,
              icon: Icon(Icons.refresh_rounded, size: R.icon(19)),
              label: Text(
                "Reset",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: R.text(14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(17)),
                  side: BorderSide(color: Colors.black.withOpacity(0.05)),
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
      height: R.buttonH(58),
      child: ElevatedButton(
        onPressed: checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(20)),
          ),
        ),
        child: Text(
          "Check Answer",
          style: GoogleFonts.montserrat(
            fontSize: R.text(16),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
