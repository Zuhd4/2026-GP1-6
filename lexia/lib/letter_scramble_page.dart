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
    const collectionName = 'vocabulary';

    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(collectionName)
        .where('level', isEqualTo: widget.level)
        .orderBy('shuffle_key')
        .startAt([randomValue])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      snapshot = await _firestore
          .collection(collectionName)
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete the word first."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isChecking = true;
    });

    if (userAnswer == targetWord) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Great Job!"),
          content: Text(
            "You spelled the word correctly: $targetWord",
            style: GoogleFonts.montserrat(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Next"),
            ),
          ],
        ),
      );

      await loadNewWord();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Try again!"),
          duration: Duration(seconds: 2),
        ),
      );

      if (!mounted) return;
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
        title: Text(
          "Letter Scramble",
          style: GoogleFonts.fredoka(
            color: const Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadNewWord,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
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
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Arrange the letters to form the correct word",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Level ${widget.level}",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6A5ACD),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          currentAnswer,
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: const Color(0xFF6A5ACD),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: List.generate(scrambledLetters.length, (index) {
                        final letter = scrambledLetters[index];

                        return GestureDetector(
                          onTap: () => onLetterTap(index),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: letter.isEmpty
                                  ? Colors.grey.shade200
                                  : const Color(0xFF6A5ACD),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: letter.isEmpty
                                      ? Colors.transparent
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: removeLastLetter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.backspace_outlined),
                          label: Text(
                            "Delete",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: resetWord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            "Reset",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BAE94),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          "Check Answer",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
