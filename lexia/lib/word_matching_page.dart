import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_typography.dart';
import 'widgets/lexia_popup.dart';
import 'level_complete_page.dart';
import 'responsive_helper.dart';

class WordMatchingPage extends StatefulWidget {
  final int level;
  final String childId;

  const WordMatchingPage({
    super.key,
    required this.level,
    required this.childId,
  });

  @override
  State<WordMatchingPage> createState() => _WordMatchingPageState();
}

class _WordMatchingPageState extends State<WordMatchingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);
  static const Color blue = Color(0xFF5B96CA);
  static const Color redError = Color(0xFFD94B43);

  final int totalRounds = 3;
  final int pairsPerRound = 3;
  final int maxAttemptsPerRound = 3;
  final int requiredCorrectToPass =
      2; // Requires at least 2 stars/completed rounds

  List<Map<String, String>> poolOfWords = [];
  Set<String> usedWordsInSession = {};

  int currentRoundIndex = 0;
  List<String> availableWords = [];
  List<Map<String, dynamic>> roundImages = [];

  Map<String, String?> targetAssignments = {};
  Set<String> confirmedMatchedTargets = {};
  Set<String> errorTargets = {};

  int attemptsInCurrentRound = 0;
  int stars = 0;
  int correctWithoutHelp = 0;
  bool roundHadHelp = false;
  bool isShowingAnswers = false;

  bool isLoading = true;
  bool isChecking = false;
  bool useOpenDyslexic = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNewGame();
  }

  Future<List<Map<String, String>>> _fetchFreshWords() async {
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

    if (snapshot.docs.length < pairsPerRound) {
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

    final allFetchedDocs = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final word = (data['word'] ?? '').toString().trim().toLowerCase();
          final imageUrl =
              (data['image_url'] ?? data['imageUrl'] ?? data['image'] ?? '')
                  .toString()
                  .trim();
          final imageStoragePath = (data['image_storage_path'] ?? '')
              .toString()
              .trim();

          return {
            'word': word,
            'imageUrl': imageUrl,
            'imageStoragePath': imageStoragePath,
          };
        })
        .where((item) => (item['word'] ?? '').isNotEmpty)
        .toList();

    final unusedWords = allFetchedDocs
        .where((item) => !usedWordsInSession.contains(item['word']))
        .toList();

    List<Map<String, String>> finalSelection = [];

    if (unusedWords.length >= pairsPerRound) {
      unusedWords.shuffle();
      finalSelection = unusedWords;
    } else {
      finalSelection.addAll(unusedWords);
      final reusedWords =
          allFetchedDocs
              .where((item) => usedWordsInSession.contains(item['word']))
              .toList()
            ..shuffle();

      for (var wordItem in reusedWords) {
        if (finalSelection.length >= (totalRounds * pairsPerRound)) break;
        finalSelection.add(wordItem);
      }
    }

    return finalSelection;
  }

  Future<void> loadNewGame() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isChecking = false;
      errorMessage = null;

      poolOfWords.clear();
      usedWordsInSession.clear();
      currentRoundIndex = 0;
      stars = 0;
      correctWithoutHelp = 0;
    });

    try {
      final fetched = await _fetchFreshWords();

      if (fetched.length < pairsPerRound) {
        if (!mounted) return;
        setState(() {
          errorMessage = "Not enough words available for this level.";
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        poolOfWords = fetched;
        isLoading = false;
      });

      _startNextRound();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to load words: $e";
        isLoading = false;
      });
    }
  }

  void _startNextRound() async {
    if (poolOfWords.length < pairsPerRound) {
      final extraWords = await _fetchFreshWords();
      poolOfWords.addAll(extraWords);
    }

    final roundWordsSlice = poolOfWords.take(pairsPerRound).toList();
    if (poolOfWords.length >= pairsPerRound) {
      poolOfWords.removeRange(0, pairsPerRound);
    }

    List<Map<String, dynamic>> preparedImages = [];
    List<String> wordsList = [];

    for (var item in roundWordsSlice) {
      final word = item['word']!;
      wordsList.add(word);
      usedWordsInSession.add(word);

      final futureUrl = _getImageDownloadUrl(
        storagePath: item['imageStoragePath'] ?? '',
        fallbackUrl: item['imageUrl'] ?? '',
      );

      preparedImages.add({'word': word, 'futureUrl': futureUrl});
    }

    preparedImages.shuffle();

    int shuffleCount = 0;
    do {
      wordsList.shuffle();
      shuffleCount++;
    } while (_isSameOrder(wordsList, preparedImages) && shuffleCount < 10);

    Map<String, String?> initialTargets = {};
    for (var img in preparedImages) {
      initialTargets[img['word']] = null;
    }

    setState(() {
      availableWords = wordsList;
      roundImages = preparedImages;
      targetAssignments = initialTargets;
      confirmedMatchedTargets.clear();
      errorTargets.clear();
      attemptsInCurrentRound = 0;
      roundHadHelp = false;
      isShowingAnswers = false;
      isChecking = false;
    });
  }

  bool _isSameOrder(List<String> words, List<Map<String, dynamic>> images) {
    if (words.length != images.length || words.length <= 1) return false;
    for (int i = 0; i < words.length; i++) {
      if (words[i] != images[i]['word']) {
        return false;
      }
    }
    return true;
  }

  Future<String?> _getImageDownloadUrl({
    required String storagePath,
    required String fallbackUrl,
  }) async {
    try {
      if (storagePath.isNotEmpty) {
        final url = await FirebaseStorage.instance
            .ref(storagePath)
            .getDownloadURL();
        if (url.isNotEmpty) return url;
      }
    } catch (e) {
      debugPrint("Storage error fallback: $e");
    }

    if (fallbackUrl.isNotEmpty) {
      return fallbackUrl;
    }
    return null;
  }

  void _handleWordDrop(String targetWord, String droppedWord) {
    if (isChecking ||
        isShowingAnswers ||
        confirmedMatchedTargets.contains(targetWord)) {
      return;
    }

    setState(() {
      targetAssignments.forEach((key, val) {
        if (val == droppedWord && key != targetWord) {
          targetAssignments[key] = null;
        }
      });

      final oldWordInTarget = targetAssignments[targetWord];
      if (oldWordInTarget != null && oldWordInTarget != droppedWord) {
        availableWords.add(oldWordInTarget);
      }

      targetAssignments[targetWord] = droppedWord;
      availableWords.remove(droppedWord);
      errorTargets.remove(targetWord);
    });
  }

  void _removeWordFromTarget(String targetWord) {
    if (isChecking ||
        isShowingAnswers ||
        confirmedMatchedTargets.contains(targetWord)) {
      return;
    }

    final assignedWord = targetAssignments[targetWord];
    if (assignedWord != null) {
      setState(() {
        availableWords.add(assignedWord);
        targetAssignments[targetWord] = null;
        errorTargets.remove(targetWord);
      });
    }
  }

  Future<void> _checkSubmittedAnswers() async {
    if (isChecking || isShowingAnswers) return;

    final unassignedCount = targetAssignments.values
        .where((val) => val == null)
        .length;
    if (unassignedCount > 0) {
      await _showSimpleDialog(
        title: "Arrange all words",
        message: "Drag all words to the picture slots before checking.",
        icon: Icons.edit_rounded,
        iconColor: primaryPurple,
      );
      return;
    }

    setState(() {
      isChecking = true;
      errorTargets.clear();
    });

    bool allCorrect = true;
    List<String> failedTargets = [];

    targetAssignments.forEach((targetWord, assignedWord) {
      if (targetWord == assignedWord) {
        confirmedMatchedTargets.add(targetWord);
      } else {
        allCorrect = false;
        failedTargets.add(targetWord);
      }
    });

    if (allCorrect) {
      stars++;
      if (!roundHadHelp) {
        correctWithoutHelp++;
      }
      await _showStarDialog();
      await _goToNextRoundOrFinish();
    } else {
      attemptsInCurrentRound++;
      roundHadHelp = true;

      if (attemptsInCurrentRound >= maxAttemptsPerRound) {
        setState(() {
          for (var img in roundImages) {
            final w = img['word'] as String;
            targetAssignments[w] = w;
            confirmedMatchedTargets.add(w);
          }
          availableWords.clear();
          errorTargets.clear();
          isShowingAnswers = true;
          isChecking = false;
        });

        await _showSimpleDialog(
          title: "Good try!",
          message: "The correct matches are displayed on the screen.",
          icon: Icons.lightbulb_rounded,
          iconColor: Colors.amber,
        );
      } else {
        await _showSimpleDialog(
          title: "Try again",
          message:
              "You have ${maxAttemptsPerRound - attemptsInCurrentRound} attempt(s) left.",
          icon: Icons.refresh_rounded,
          iconColor: primaryPurple,
        );

        setState(() {
          errorTargets.addAll(failedTargets);
        });

        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              for (var tWord in failedTargets) {
                final wrongWord = targetAssignments[tWord];
                if (wrongWord != null) {
                  availableWords.add(wrongWord);
                  targetAssignments[tWord] = null;
                }
              }
              errorTargets.clear();
              isChecking = false;
            });
          }
        });
      }
    }
  }

  Future<void> _goToNextRoundOrFinish() async {
    if (!mounted) return;

    if (currentRoundIndex < totalRounds - 1) {
      setState(() {
        currentRoundIndex++;
      });
      _startNextRound();
    } else {
      await _finishRound();
    }
  }

  Future<void> _saveWordMatchingProgress() async {
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

    final Map<String, dynamic> oldWordMatching = Map<String, dynamic>.from(
      currentLevelProgress['wordMatching'] ?? {},
    );

    final int oldBestStars =
        ((oldWordMatching['bestStars'] as num?)?.toInt() ?? 0);
    final int oldCompletedCount =
        ((oldWordMatching['completedCount'] as num?)?.toInt() ?? 0);
    final int newBestStars = stars > oldBestStars ? stars : oldBestStars;

    currentLevelProgress['wordMatching'] = {
      'completed': true,
      'completedCount': oldCompletedCount + 1,
      'stars': stars,
      'bestStars': newBestStars,
      'lastScore': stars,
      'totalWords': totalRounds * pairsPerRound,
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
    // Requires collecting at least 2 stars (2 completed rounds) to pass
    final passed = stars >= requiredCorrectToPass;

    if (passed) {
      if (!mounted) return;

      try {
        await _saveWordMatchingProgress();
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
            "You earned $stars/3 stars. You need at least 2/3 stars to unlock the next level.",
        icon: Icons.lock_outline_rounded,
        iconColor: primaryPurple,
      );

      await loadNewGame();
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
                                    SizedBox(height: R.space(12)),
                                    Text(
                                      "Drag each word tile to its matching picture!",
                                      textAlign: TextAlign.center,
                                      style: AppTypography.getStyle(
                                        useOpenDyslexic: useOpenDyslexic,
                                        fontSize: R.text(13.5),
                                        fontWeight: FontWeight.w600,
                                        color: textDark.withOpacity(0.7),
                                      ),
                                    ),
                                    SizedBox(height: R.space(20)),

                                    _buildImageTargets(),

                                    SizedBox(height: R.space(24)),

                                    if (isShowingAnswers)
                                      _buildNextRoundButton(useOpenDyslexic)
                                    else ...[
                                      _buildWordBank(useOpenDyslexic),
                                      SizedBox(height: R.space(20)),
                                      _buildCheckButton(useOpenDyslexic),
                                    ],
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
              "Word Matching",
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
          "Word ${currentRoundIndex + 1}/$totalRounds",
          style: AppTypography.getStyle(
            useOpenDyslexic: useOpenDyslexic,
            fontSize: R.text(16),
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

  Widget _buildImageTargets() {
    return Column(
      children: roundImages.map((imgData) {
        final targetWord = imgData['word'] as String;
        final assignedWord = targetAssignments[targetWord];
        final isConfirmed = confirmedMatchedTargets.contains(targetWord);
        final isHasError = errorTargets.contains(targetWord);
        final futureUrl = imgData['futureUrl'] as Future<String?>;

        return Padding(
          padding: EdgeInsets.only(bottom: R.space(16)),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) =>
                !isConfirmed && !isShowingAnswers,
            onAcceptWithDetails: (details) {
              _handleWordDrop(targetWord, details.data);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              Color borderColor = primaryPurple.withOpacity(0.15);
              Color bgColor = Colors.white;

              if (isConfirmed) {
                borderColor = green;
                bgColor = green.withOpacity(0.08);
              } else if (isHasError) {
                borderColor = redError;
                bgColor = redError.withOpacity(0.08);
              } else if (assignedWord != null) {
                borderColor = blue;
                bgColor = blue.withOpacity(0.08);
              } else if (isHovering) {
                borderColor = blue;
                bgColor = blue.withOpacity(0.08);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.all(R.space(12)),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(R.radius(24)),
                  border: Border.all(
                    color: borderColor,
                    width:
                        isConfirmed ||
                            isHasError ||
                            assignedWord != null ||
                            isHovering
                        ? 2.5
                        : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: R.icon(80),
                      height: R.icon(80),
                      padding: EdgeInsets.all(R.space(4)),
                      decoration: BoxDecoration(
                        color: softCream,
                        borderRadius: BorderRadius.circular(R.radius(16)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(R.radius(12)),
                        child: FutureBuilder<String?>(
                          future: futureUrl,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: primaryPurple,
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            final imageUrl = snapshot.data;
                            if (imageUrl == null || imageUrl.isEmpty) {
                              return Icon(
                                Icons.image_rounded,
                                size: R.icon(32),
                                color: primaryPurple.withOpacity(0.3),
                              );
                            }

                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_not_supported_rounded,
                                color: primaryPurple.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(width: R.space(16)),

                    Expanded(
                      child: _buildTargetSlotContent(
                        targetWord: targetWord,
                        assignedWord: assignedWord,
                        isConfirmed: isConfirmed,
                        isHovering: isHovering,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetSlotContent({
    required String targetWord,
    required String? assignedWord,
    required bool isConfirmed,
    required bool isHovering,
  }) {
    final bool canDrag =
        assignedWord != null &&
        !isConfirmed &&
        !isShowingAnswers &&
        !isChecking;

    Widget slotTile = Container(
      height: R.space(52),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isConfirmed
            ? green.withOpacity(0.15)
            : assignedWord != null
            ? blue.withOpacity(0.15)
            : Colors.white,
        borderRadius: BorderRadius.circular(R.radius(16)),
        border: Border.all(
          color: isConfirmed
              ? green
              : assignedWord != null
              ? blue
              : primaryPurple.withOpacity(0.15),
          style: isConfirmed || assignedWord != null
              ? BorderStyle.solid
              : BorderStyle.none,
        ),
      ),
      child: Text(
        assignedWord != null
            ? assignedWord.toUpperCase()
            : isHovering
            ? "Drop Here!"
            : "Drop Word Here",
        style: GoogleFonts.fredoka(
          fontSize: R.text(16),
          fontWeight: FontWeight.bold,
          color: isConfirmed
              ? green
              : assignedWord != null
              ? blue
              : isHovering
              ? blue
              : textDark.withOpacity(0.35),
        ),
      ),
    );

    if (!canDrag) {
      return GestureDetector(
        onTap: () => _removeWordFromTarget(targetWord),
        child: slotTile,
      );
    }

    return Draggable<String>(
      data: assignedWord,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: R.space(20),
            vertical: R.space(12),
          ),
          decoration: BoxDecoration(
            color: primaryPurple,
            borderRadius: BorderRadius.circular(R.radius(16)),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            assignedWord.toUpperCase(),
            style: GoogleFonts.fredoka(
              fontSize: R.text(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        height: R.space(52),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(R.radius(16)),
          border: Border.all(
            color: primaryPurple.withOpacity(0.15),
            style: BorderStyle.none,
          ),
        ),
        child: Text(
          "Drop Word Here",
          style: GoogleFonts.fredoka(
            fontSize: R.text(16),
            fontWeight: FontWeight.bold,
            color: textDark.withOpacity(0.25),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _removeWordFromTarget(targetWord),
        child: slotTile,
      ),
    );
  }

  Widget _buildCheckButton(bool useOpenDyslexic) {
    return SizedBox(
      width: double.infinity,
      height: R.buttonH(56),
      child: ElevatedButton(
        onPressed: _checkSubmittedAnswers,
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

  Widget _buildNextRoundButton(bool useOpenDyslexic) {
    return SizedBox(
      width: double.infinity,
      height: R.buttonH(56),
      child: ElevatedButton(
        onPressed: _goToNextRoundOrFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(20)),
          ),
        ),
        child: Text(
          currentRoundIndex < totalRounds - 1 ? "Next Round" : "Finish",
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

  Widget _buildWordBank(bool useOpenDyslexic) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return !isChecking &&
            !isShowingAnswers &&
            targetAssignments.containsValue(details.data);
      },
      onAcceptWithDetails: (details) {
        final droppedWord = details.data;
        targetAssignments.forEach((targetWord, assignedWord) {
          if (assignedWord == droppedWord) {
            _removeWordFromTarget(targetWord);
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.all(R.space(16)),
          decoration: BoxDecoration(
            color: isHovering
                ? primaryPurple.withOpacity(0.08)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(R.radius(24)),
            border: Border.all(
              color: isHovering
                  ? primaryPurple
                  : primaryPurple.withOpacity(0.1),
              width: isHovering ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                "Word Pool",
                style: AppTypography.getStyle(
                  useOpenDyslexic: useOpenDyslexic,
                  fontSize: R.text(12),
                  fontWeight: FontWeight.w600,
                  color: textDark.withOpacity(0.5),
                ),
              ),
              SizedBox(height: R.space(12)),
              if (availableWords.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: R.space(8)),
                  child: Text(
                    "All words placed!",
                    style: AppTypography.getStyle(
                      useOpenDyslexic: useOpenDyslexic,
                      fontSize: R.text(12),
                      fontWeight: FontWeight.w500,
                      color: textDark.withOpacity(0.35),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: R.space(10),
                  runSpacing: R.space(10),
                  alignment: WrapAlignment.center,
                  children: availableWords.map((word) {
                    return Draggable<String>(
                      data: word,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: R.space(20),
                            vertical: R.space(12),
                          ),
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(R.radius(16)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            word.toUpperCase(),
                            style: GoogleFonts.fredoka(
                              fontSize: R.text(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildWordTile(word),
                      ),
                      child: _buildWordTile(word),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordTile(String word) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(18),
        vertical: R.space(12),
      ),
      decoration: BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.circular(R.radius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        word.toUpperCase(),
        style: GoogleFonts.fredoka(
          fontSize: R.text(16),
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
            onPressed: loadNewGame,
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
