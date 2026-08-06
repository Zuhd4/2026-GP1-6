import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';
import 'level_complete_page.dart';
import 'responsive_helper.dart';
import 'widgets/lexia_popup.dart';

class ListenAndSpellPage extends StatefulWidget {
  final int level;
  final String childId;

  const ListenAndSpellPage({
    super.key,
    required this.level,
    required this.childId,
  });

  @override
  State<ListenAndSpellPage> createState() => _ListenAndSpellPageState();
}

class _ListenAndSpellPageState extends State<ListenAndSpellPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts _flutterTts = FlutterTts();
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
  Set<String> usedWordsInSession = {};

  int currentWordIndex = 0;
  int attemptsForCurrentWord = 0;
  int stars = 0;
  int correctWithoutHelp = 0;

  String targetWord = "";
  List<String> selectedLetters = [];

  bool isLoading = true;
  bool isChecking = false;
  bool isSpeaking = false;
  bool useOpenDyslexic = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initTts();
    loadNewRound();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setQueueMode(0);

      try {
        final engines = await _flutterTts.getEngines;
        if (engines is List && engines.contains("com.google.android.tts")) {
          await _flutterTts.setEngine("com.google.android.tts");
        }
      } catch (e) {
        debugPrint("Google TTS engine is unavailable: $e");
      }

      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        final englishVoices = voices.whereType<Map>().where((voice) {
          final locale = (voice["locale"] ?? "")
              .toString()
              .replaceAll("_", "-")
              .toLowerCase();
          return locale == "en-us" || locale.startsWith("en-us-");
        }).toList();

        Map? selectedVoice;

        for (final voice in englishVoices) {
          final name = (voice["name"] ?? "").toString().toLowerCase();
          final networkRequired =
              voice["network_required"] == true ||
              voice["networkRequired"] == true;

          if (!networkRequired &&
              !name.contains("low") &&
              !name.contains("compact")) {
            selectedVoice = voice;
            break;
          }
        }

        selectedVoice ??= englishVoices.isNotEmpty ? englishVoices.first : null;

        if (selectedVoice != null) {
          await _flutterTts.setVoice({
            "name": selectedVoice["name"],
            "locale": selectedVoice["locale"],
          });
        }
      }

      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() => isSpeaking = true);
        }
      });

      void finishSpeaking() {
        if (mounted) {
          setState(() => isSpeaking = false);
        }
      }

      _flutterTts.setCompletionHandler(finishSpeaking);
      _flutterTts.setCancelHandler(finishSpeaking);
      _flutterTts.setErrorHandler((message) {
        debugPrint("TTS error: $message");
        finishSpeaking();
      });
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<List<Map<String, String>>> _fetchRoundWords() async {
    const collectionName = 'vocabulary_test';
    final randomValue = _random.nextDouble();

    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: 'done')
        .where('validation_status', isEqualTo: 'done')
        .where('is_safe', isEqualTo: true)
        .where('is_educational', isEqualTo: true)
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
          .where('is_safe', isEqualTo: true)
          .where('is_educational', isEqualTo: true)
          .where('level', isEqualTo: widget.level)
          .orderBy('shuffle_key')
          .limit(30)
          .get();
    }

    final allFetchedDocs = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final word = (data['word'] ?? '').toString().trim().toLowerCase();
          return {'word': word};
        })
        .where((item) => (item['word'] ?? '').isNotEmpty)
        .toList();

    final unusedWords = allFetchedDocs
        .where((item) => !usedWordsInSession.contains(item['word']))
        .toList();

    List<Map<String, String>> selected = [];

    if (unusedWords.length >= totalWordsPerRound) {
      unusedWords.shuffle();
      selected = unusedWords.take(totalWordsPerRound).toList();
    } else {
      selected.addAll(unusedWords);
      final reused =
          allFetchedDocs
              .where((item) => usedWordsInSession.contains(item['word']))
              .toList()
            ..shuffle();

      for (var w in reused) {
        if (selected.length >= totalWordsPerRound) break;
        selected.add(w);
      }
    }

    return selected;
  }

  Future<void> loadNewRound() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isChecking = false;
      errorMessage = null;

      roundWords.clear();
      usedWordsInSession.clear();
      currentWordIndex = 0;
      attemptsForCurrentWord = 0;
      stars = 0;
      correctWithoutHelp = 0;

      targetWord = "";
      selectedLetters.clear();
    });

    try {
      final fetchedWords = await _fetchRoundWords();

      if (fetchedWords.length < totalWordsPerRound) {
        if (!mounted) return;
        setState(() {
          errorMessage = "Not enough words found for this level.";
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      for (var item in fetchedWords) {
        if (item['word'] != null) {
          usedWordsInSession.add(item['word']!);
        }
      }

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
    attemptsForCurrentWord = 0;
    selectedLetters = [];
  }

  Future<void> _speakWord({required bool slow}) async {
    if (targetWord.isEmpty || isSpeaking) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      if (slow) {
        await _flutterTts.setSpeechRate(0.15);
      } else {
        await _flutterTts.setSpeechRate(0.40);
      }

      await _flutterTts.speak(targetWord, focus: true);
    } catch (e) {
      debugPrint("TTS error for '$targetWord': $e");

      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    }
  }

  void _onKeyTap(String letter) {
    if (isLoading || isChecking) return;
    if (selectedLetters.length >= targetWord.length) return;

    setState(() {
      selectedLetters.add(letter);
    });
  }

  void _removeLastLetter() {
    if (isLoading || isChecking || selectedLetters.isEmpty) return;
    setState(() {
      selectedLetters.removeLast();
    });
  }

  void _resetWord() {
    if (isLoading || isChecking) return;
    setState(() {
      selectedLetters.clear();
    });
  }

  Future<void> _checkAnswer() async {
    if (targetWord.isEmpty || isChecking || isLoading) return;

    final userAnswer = selectedLetters.join().toLowerCase();
    final correctAnswer = targetWord.replaceAll(' ', '').toLowerCase();

    if (userAnswer.length != correctAnswer.length) {
      await _showSimpleDialog(
        title: "Arrange all letters",
        message:
            "Arrange all letters to form the correct word before checking.",
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
      if (attemptsForCurrentWord == 0) {
        correctWithoutHelp++;
      }

      await _showStarDialog();
      await _goToNextWordOrFinishRound();
    } else {
      attemptsForCurrentWord++;

      if (attemptsForCurrentWord >= maxAttemptsPerWord) {
        await _showSimpleDialog(
          title: "Good try!",
          message: "The correct spelling is: '${targetWord.toUpperCase()}'",
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
      await _finishRound();
    }
  }

  Future<void> _saveListenAndSpellProgress() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty || widget.childId.isEmpty) return;

    final childRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc(widget.childId);

    final String levelKey = 'level_${widget.level}';
    final doc = await childRef.get();
    final data = doc.data();

    final Map<String, dynamic> currentProgress = Map<String, dynamic>.from(
      data?['gameProgress'] ?? {},
    );

    final Map<String, dynamic> currentLevelProgress = Map<String, dynamic>.from(
      currentProgress[levelKey] ?? {},
    );

    final Map<String, dynamic> oldGame = Map<String, dynamic>.from(
      currentLevelProgress['listenAndSpell'] ?? {},
    );

    final int oldBestStars = ((oldGame['bestStars'] as num?)?.toInt() ?? 0);
    final int oldCompletedCount =
        ((oldGame['completedCount'] as num?)?.toInt() ?? 0);
    final int newBestStars = stars > oldBestStars ? stars : oldBestStars;

    currentLevelProgress['listenAndSpell'] = {
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
  }

  Future<void> _finishRound() async {
    final passed = correctWithoutHelp >= requiredCorrectToPass;

    if (passed) {
      if (!mounted) return;

      try {
        await _saveListenAndSpellProgress();
      } catch (e) {
        debugPrint("Failed to save progress: $e");
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
      useOpenDyslexic: useOpenDyslexic,
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
      useOpenDyslexic: useOpenDyslexic,
      barrierDismissible: false,
    );
  }

  String get currentAnswerDisplay {
    if (targetWord.isEmpty) return "";
    List<String> display = [];

    for (int i = 0; i < targetWord.length; i++) {
      if (i < selectedLetters.length) {
        display.add(selectedLetters[i].toUpperCase());
      } else {
        display.add('_');
      }
    }
    return display.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};
        useOpenDyslexic = userData['useOpenDyslexicFont'] == true;

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
                    child: _buildHeader(context, useOpenDyslexic),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                            ),
                          )
                        : errorMessage != null
                        ? _buildErrorState(useOpenDyslexic)
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
                                  R.space(10),
                                  R.pagePad,
                                  R.safeBottom + R.space(24),
                                ),
                                child: Column(
                                  children: [
                                    _buildProgressHeader(useOpenDyslexic),
                                    SizedBox(height: R.space(14)),
                                    _buildAudioCard(useOpenDyslexic),
                                    SizedBox(height: R.space(18)),
                                    _buildSpellingDisplay(),
                                    SizedBox(height: R.space(18)),
                                    _buildKeyboard(),
                                    SizedBox(height: R.space(16)),
                                    _buildActionButtons(useOpenDyslexic),
                                    SizedBox(height: R.space(14)),
                                    _buildCheckButton(useOpenDyslexic),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool useOpenDyslexic) {
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
              "Listen and Spell",
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
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

  Widget _buildProgressHeader(bool useOpenDyslexic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Word ${currentWordIndex + 1}/$totalWordsPerRound",
          style: AppTypography.getStyle(
            useOpenDyslexic: useOpenDyslexic,
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

  Widget _buildAudioCard(bool useOpenDyslexic) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: isSpeaking ? null : () => _speakWord(slow: false),
                child: Container(
                  width: R.icon(72),
                  height: R.icon(72),
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? primaryPurple.withOpacity(0.55)
                        : primaryPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSpeaking
                        ? Icons.graphic_eq_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: R.icon(36),
                  ),
                ),
              ),
              SizedBox(width: R.space(16)),
              GestureDetector(
                onTap: isSpeaking ? null : () => _speakWord(slow: true),
                child: Container(
                  width: R.icon(56),
                  height: R.icon(56),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.snooze_rounded,
                    color: primaryPurple,
                    size: R.icon(26),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: R.space(12)),
          Text(
            "Tap to listen to the word",
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(13),
              fontWeight: FontWeight.w600,
              color: textDark.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellingDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(16),
        vertical: R.space(14),
      ),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(R.radius(20)),
      ),
      child: Center(
        child: Text(
          currentAnswerDisplay,
          style: GoogleFonts.fredoka(
            fontSize: R.text(22),
            fontWeight: FontWeight.bold,
            letterSpacing: R.space(2),
            color: primaryPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    const letters = [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
    ];

    return Wrap(
      spacing: R.space(6),
      runSpacing: R.space(6),
      alignment: WrapAlignment.center,
      children: letters.map((letter) {
        return GestureDetector(
          onTap: () => _onKeyTap(letter),
          child: Container(
            width: R.icon(38),
            height: R.icon(38),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(10)),
              border: Border.all(color: primaryPurple.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter.toUpperCase(),
                style: GoogleFonts.fredoka(
                  fontSize: R.text(16),
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(bool useOpenDyslexic) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: R.buttonH(48),
            child: ElevatedButton.icon(
              onPressed: _removeLastLetter,
              icon: Icon(Icons.backspace_outlined, size: R.icon(18)),
              label: Text(
                "Delete",
                style: AppTypography.getStyle(
                  useOpenDyslexic: useOpenDyslexic,
                  fontWeight: FontWeight.w600,
                  fontSize: R.text(13),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD94B43),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(16)),
                  side: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: R.space(12)),
        Expanded(
          child: SizedBox(
            height: R.buttonH(48),
            child: ElevatedButton.icon(
              onPressed: _resetWord,
              icon: Icon(Icons.refresh_rounded, size: R.icon(18)),
              label: Text(
                "Reset",
                style: AppTypography.getStyle(
                  useOpenDyslexic: useOpenDyslexic,
                  fontWeight: FontWeight.w600,
                  fontSize: R.text(13),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(R.radius(16)),
                  side: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckButton(bool useOpenDyslexic) {
    return SizedBox(
      width: double.infinity,
      height: R.buttonH(56),
      child: ElevatedButton(
        onPressed: _checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(20)),
          ),
        ),
        child: Text(
          "Check Answer",
          style: AppTypography.getStyle(
            useOpenDyslexic: useOpenDyslexic,
            fontSize: R.text(16),
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool useOpenDyslexic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(R.radius(16)),
              ),
            ),
            child: Text(
              "Try Again",
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
