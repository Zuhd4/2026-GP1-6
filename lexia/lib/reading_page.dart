import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'app_typography.dart';
import 'responsive_helper.dart';

// ============================================================
// READING LIBRARY
// ============================================================

class ReadingPage extends StatelessWidget {
  final String childId;

  const ReadingPage({super.key, required this.childId});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(105);

    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty || childId.isEmpty) {
      return const Scaffold(
        backgroundColor: ivoryWhite,
        body: Center(child: Text('Child profile not found')),
      );
    }

    final childRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc(childId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};
        final bool useOpenDyslexic = userData['useOpenDyslexicFont'] == true;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: childRef.snapshots(),
          builder: (context, childSnap) {
            final childData = childSnap.data?.data() ?? {};

            final Map<String, dynamic> readingProgress =
                Map<String, dynamic>.from(childData['readingProgress'] ?? {});

            double bestScoreForLevel(int level) {
              final String levelKey = 'level_$level';

              final Map<String, dynamic> levelProgress =
                  Map<String, dynamic>.from(readingProgress[levelKey] ?? {});

              final Map<String, dynamic> storyReading =
                  Map<String, dynamic>.from(
                    levelProgress['storyReading'] ?? {},
                  );

              return ((storyReading['bestScore'] as num?)?.toDouble() ?? 0.0);
            }

            bool isBookUnlocked(int level) {
              // Book 1 is always available.
              if (level == 1) return true;

              // Every next book opens only when the previous book's
              // BEST saved score is 50% or higher.
              return bestScoreForLevel(level - 1) >= 50.0;
            }

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
                child: R.pageWrap(
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
                        Text(
                          'My Library',
                          style: AppTypography.getStyle(
                            useOpenDyslexic: useOpenDyslexic,
                            fontSize: R.text(21),
                            fontWeight: FontWeight.w500,
                            color: textDark.withOpacity(0.9),
                          ),
                        ),

                        SizedBox(height: R.space(2)),

                        Text(
                          '✨ Score 50% or more to unlock the next story',
                          style: AppTypography.getStyle(
                            useOpenDyslexic: useOpenDyslexic,
                            fontSize: R.text(12),
                            color: Colors.black45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: R.space(10)),

                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('reading_books')
                              .orderBy('level')
                              .snapshots(),
                          builder: (context, booksSnap) {
                            if (booksSnap.connectionState ==
                                ConnectionState.waiting) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: R.space(50),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: primaryGreen,
                                  ),
                                ),
                              );
                            }

                            if (booksSnap.hasError) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: R.space(30),
                                ),
                                child: Text(
                                  'Could not load the books.',
                                  style: AppTypography.getStyle(
                                    useOpenDyslexic: useOpenDyslexic,
                                    fontSize: R.text(13),
                                    color: Colors.redAccent,
                                  ),
                                ),
                              );
                            }

                            final docs = booksSnap.data?.docs ?? [];

                            final Map<String, Map<String, dynamic>>
                            bookDataById = {
                              for (final doc in docs) doc.id: doc.data(),
                            };

                            final book1 = bookDataById['book_1'] ?? {};
                            final book2 = bookDataById['book_2'] ?? {};
                            final book3 = bookDataById['book_3'] ?? {};
                            final book4 = bookDataById['book_4'] ?? {};
                            final book5 = bookDataById['book_5'] ?? {};
                            final book6 = bookDataById['book_6'] ?? {};

                            final List<Map<String, dynamic>> books = [
                              {
                                'id': 'book_1',
                                'name': book1['title'] ?? 'Book 1',
                                'coverPath':
                                    book1['cover_image_storage_path'] ?? '',
                                'level': 1,
                                'locked': !isBookUnlocked(1),
                              },
                              {
                                'id': 'book_2',
                                'name': book2['title'] ?? 'Book 2',
                                'coverPath':
                                    book2['cover_image_storage_path'] ?? '',
                                'level': 2,
                                'locked': !isBookUnlocked(2),
                              },
                              {
                                'id': 'book_3',
                                'name': book3['title'] ?? 'Book 3',
                                'coverPath':
                                    book3['cover_image_storage_path'] ?? '',
                                'level': 3,
                                'locked': !isBookUnlocked(3),
                              },
                              {
                                'id': 'book_4',
                                'name': book4['title'] ?? 'Book 4',
                                'coverPath':
                                    book4['cover_image_storage_path'] ?? '',
                                'level': 4,
                                'locked': !isBookUnlocked(4),
                              },
                              {
                                'id': 'book_5',
                                'name': book5['title'] ?? 'Book 5',
                                'coverPath':
                                    book5['cover_image_storage_path'] ?? '',
                                'level': 5,
                                'locked': !isBookUnlocked(5),
                              },
                              {
                                'id': 'book_6',
                                'name': book6['title'] ?? 'Book 6',
                                'coverPath':
                                    book6['cover_image_storage_path'] ?? '',
                                'level': 6,
                                'locked': !isBookUnlocked(6),
                              },
                            ];

                            return Column(
                              children: [
                                for (int i = 0; i < 3; i++)
                                  _WoodenShelfRow(
                                    items: books.sublist(i * 2, i * 2 + 2),
                                    useOpenDyslexic: useOpenDyslexic,
                                    onStoryTap: (book) {
                                      final bool isLocked =
                                          book['locked'] == true;
                                      if (isLocked) return;

                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BookReaderPage(
                                            bookId: book['id'] as String,
                                            title: book['name'] as String,
                                            coverPath: (book['coverPath'] ?? '')
                                                .toString(),
                                            level: book['level'] as int,
                                            childId: childId,
                                            useOpenDyslexic: useOpenDyslexic,
                                          ),
                                        ),
                                      );
                                    },
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
            );
          },
        );
      },
    );
  }
}

// ============================================================
// WOODEN SHELF
// ============================================================

class _WoodenShelfRow extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool useOpenDyslexic;
  final ValueChanged<Map<String, dynamic>> onStoryTap;

  const _WoodenShelfRow({
    required this.items,
    required this.useOpenDyslexic,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: R.space(20)),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: -R.space(10),
            child: Container(
              width: R.sw * 0.7,
              height: R.space(12),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: R.space(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.radius(4)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF1E4D3), Color(0xFFD7C2A9)],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: R.space(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((book) {
                return _LibraryBook(
                  data: book,
                  isLocked: book['locked'] == true,
                  useOpenDyslexic: useOpenDyslexic,
                  onTap: () => onStoryTap(book),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOOK COVER
// ============================================================

class _LibraryBook extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLocked;
  final bool useOpenDyslexic;
  final VoidCallback onTap;

  const _LibraryBook({
    required this.data,
    required this.isLocked,
    required this.useOpenDyslexic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: R.icon(120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: R.icon(100),
              height: R.space(130),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade300 : Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(R.radius(8)),
                  bottomRight: Radius.circular(R.radius(8)),
                  topLeft: Radius.circular(R.radius(2)),
                  bottomLeft: Radius.circular(R.radius(2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Always show the real cover, even when the book is locked.
                  if ((data['coverPath'] ?? '').toString().isNotEmpty)
                    _StorageImage(
                      storagePath: data['coverPath'] as String,
                      fit: BoxFit.cover,
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: R.icon(35),
                        color: ReadingPage.textDark.withOpacity(0.25),
                      ),
                    ),

                  Container(
                    width: R.space(6),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  if (isLocked)
                    Container(
                      color: Colors.black.withOpacity(0.28),
                      child: Center(
                        child: Container(
                          width: R.icon(44),
                          height: R.icon(44),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            color: ReadingPage.textDark.withOpacity(0.75),
                            size: R.icon(23),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: R.space(8)),

            Text(
              data['name'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
                fontSize: R.text(10.5),
                fontWeight: FontWeight.w500,
                color: isLocked
                    ? ReadingPage.textDark.withOpacity(0.4)
                    : ReadingPage.textDark.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOOK READER
// ============================================================

class BookReaderPage extends StatefulWidget {
  final String bookId;
  final String title;
  final String coverPath;
  final int level;
  final String childId;
  final bool useOpenDyslexic;

  const BookReaderPage({
    super.key,
    required this.bookId,
    required this.title,
    required this.coverPath,
    required this.level,
    required this.childId,
    required this.useOpenDyslexic,
  });

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  int _currentPage = 0;

  // ==========================================================
  // RECORDING + ASR STATE
  // ==========================================================

  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isAnalyzing = false;

  final Map<int, String> _recordingsByPage = {};

  final Map<int, Map<String, dynamic>> _assessmentByPage = {};

  // Tracks which page assessments are safely stored in Firestore.
  final Set<int> _savedPages = {};

  // Saved page results are loaded from Firestore when the book opens.
  bool _isLoadingSavedProgress = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPageProgress();
  }

  DocumentReference<Map<String, dynamic>>? get _childRef {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty || widget.childId.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc(widget.childId);
  }

  // ==========================================================
  // LOAD SAVED PAGE RESULTS
  // ==========================================================

  Future<void> _loadSavedPageProgress() async {
    final childRef = _childRef;

    if (childRef == null) {
      if (mounted) {
        setState(() {
          _isLoadingSavedProgress = false;
        });
      }
      return;
    }

    try {
      final doc = await childRef.get();
      final data = doc.data();

      final Map<String, dynamic> readingProgress = Map<String, dynamic>.from(
        data?['readingProgress'] ?? {},
      );

      final String levelKey = 'level_${widget.level}';

      final Map<String, dynamic> levelProgress = Map<String, dynamic>.from(
        readingProgress[levelKey] ?? {},
      );

      final Map<String, dynamic> storyReading = Map<String, dynamic>.from(
        levelProgress['storyReading'] ?? {},
      );

      final String savedBookId = (storyReading['bookId'] ?? '').toString();

      if (savedBookId.isNotEmpty && savedBookId != widget.bookId) {
        if (!mounted) return;

        setState(() {
          _isLoadingSavedProgress = false;
        });

        return;
      }

      // currentPageResults is used for resume / rereading.
      // If there is no active current set, fall back to the best saved pages
      // so the child can see the old result and choose Record Again or Next.
      Map<String, dynamic> savedPageResults = Map<String, dynamic>.from(
        storyReading['currentPageResults'] ?? {},
      );

      if (savedPageResults.isEmpty) {
        savedPageResults = Map<String, dynamic>.from(
          storyReading['pageResults'] ?? {},
        );
      }

      final Map<int, Map<String, dynamic>> loadedResults = {};

      for (final entry in savedPageResults.entries) {
        final String key = entry.key;

        if (!key.startsWith('page_') || entry.value is! Map) {
          continue;
        }

        final int? pageNumber = int.tryParse(key.replaceFirst('page_', ''));

        if (pageNumber == null) {
          continue;
        }

        final Map<String, dynamic> saved = Map<String, dynamic>.from(
          entry.value as Map,
        );

        loadedResults[pageNumber - 1] = {
          'page_score': saved['pageScore'],
          'correct': saved['correct'],
          'substitutions': saved['substitutions'],
          'omissions': saved['omissions'],
          'additions': saved['additions'],
          'expected_text': saved['expectedText'],
          'recognized_text': saved['recognizedText'],
          'alignment': saved['alignment'],
        };
      }

      if (!mounted) return;

      setState(() {
        _assessmentByPage.addAll(loadedResults);
        _savedPages.addAll(loadedResults.keys);
        _isLoadingSavedProgress = false;
      });

      debugPrint('✅ Loaded ${loadedResults.length} saved reading page(s)');
    } catch (e) {
      debugPrint('❌ Failed to load saved reading progress: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingSavedProgress = false;
      });
    }
  }

  // ==========================================================
  // SAVE ONE PAGE RESULT IMMEDIATELY
  // ==========================================================

  Future<void> _savePageResult({
    required int pageIndex,
    required Map<String, dynamic> result,
  }) async {
    final childRef = _childRef;

    if (childRef == null) {
      throw Exception('Child profile not found.');
    }

    final String levelKey = 'level_${widget.level}';

    final doc = await childRef.get();
    final data = doc.data();

    final Map<String, dynamic> currentProgress = Map<String, dynamic>.from(
      data?['readingProgress'] ?? {},
    );

    final Map<String, dynamic> currentLevelProgress = Map<String, dynamic>.from(
      currentProgress[levelKey] ?? {},
    );

    final Map<String, dynamic> storyReading = Map<String, dynamic>.from(
      currentLevelProgress['storyReading'] ?? {},
    );

    final Map<String, dynamic> currentPageResults = Map<String, dynamic>.from(
      storyReading['currentPageResults'] ?? storyReading['pageResults'] ?? {},
    );

    currentPageResults['page_${pageIndex + 1}'] = {
      'pageScore': result['page_score'],
      'correct': result['correct'],
      'substitutions': result['substitutions'],
      'omissions': result['omissions'],
      'additions': result['additions'],
      'expectedText': result['expected_text'],
      'recognizedText': result['recognized_text'],
      'alignment': result['alignment'],
      'savedAt': FieldValue.serverTimestamp(),
    };

    storyReading['bookId'] = widget.bookId;
    storyReading['bookTitle'] = widget.title;
    storyReading['currentPageResults'] = currentPageResults;
    storyReading['lastPageUpdated'] = pageIndex + 1;
    storyReading['updatedAt'] = FieldValue.serverTimestamp();

    if (!storyReading.containsKey('completed')) {
      storyReading['completed'] = false;
    }

    currentLevelProgress['storyReading'] = storyReading;
    currentLevelProgress['updatedAt'] = FieldValue.serverTimestamp();
    currentProgress[levelKey] = currentLevelProgress;

    await childRef.set({
      'readingProgress': currentProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('✅ Page ${pageIndex + 1} result saved to Firestore');
  }

  // ==========================================================
  // START RECORDING
  // ==========================================================

  Future<void> _startRecording() async {
    try {
      final bool hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        return;
      }

      final directory = await getTemporaryDirectory();

      final String path =
          '${directory.path}/'
          '${widget.bookId}_'
          'page_${_currentPage + 1}_'
          '${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          noiseSuppress: true,
        ),
        path: path,
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
      });

      debugPrint('🎤 Recording started');
      debugPrint('Book: ${widget.bookId}');
      debugPrint('Page: ${_currentPage + 1}');
      debugPrint('Path: $path');
    } catch (e) {
      debugPrint('Recording start error: $e');

      if (!mounted) return;
    }
  }

  // ==========================================================
  // SEND AUDIO TO LEXIA ASR BACKEND
  // ==========================================================

  Future<void> _analyzeRecording({
    required String audioPath,
    required String expectedText,
    required int pageIndex,
  }) async {
    try {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = true;
      });

      final Uri uri = Uri.parse(
        'https://lexia-asr-100861482313.me-central1.run.app/reading-assessment',
      );

      final request = http.MultipartRequest('POST', uri);

      // Expected story text.
      request.fields['expected_text'] = expectedText;

      // Child WAV recording.
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

      debugPrint('📤 Sending recording to Lexia ASR...');

      debugPrint('Expected: $expectedText');

      debugPrint('Audio: $audioPath');

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Server status: ${response.statusCode}');

      debugPrint('Server response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid response from server.');
      }

      final Map<String, dynamic> result = Map<String, dynamic>.from(decoded);

      if (!mounted) return;

      setState(() {
        _assessmentByPage[pageIndex] = result;
        _savedPages.remove(pageIndex);
      });

      try {
        await _savePageResult(pageIndex: pageIndex, result: result);

        if (mounted) {
          setState(() {
            _savedPages.add(pageIndex);
          });
        }
      } catch (e) {
        debugPrint('❌ Failed to save Page ${pageIndex + 1}: $e');
      }

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      debugPrint('✅ ASR RESULT');

      debugPrint('Expected: ${result['expected_text']}');

      debugPrint('Recognized: ${result['recognized_text']}');

      debugPrint('Score: ${result['page_score']}');

      debugPrint('Correct: ${result['correct']}');

      debugPrint('Substitutions: ${result['substitutions']}');

      debugPrint('Omissions: ${result['omissions']}');

      debugPrint('Additions: ${result['additions']}');
    } catch (e) {
      debugPrint('❌ Assessment error: $e');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  // ==========================================================
  // STOP RECORDING
  // ==========================================================

  Future<void> _stopRecording(String expectedText) async {
    try {
      final int pageIndex = _currentPage;

      final String? path = await _recorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;

        if (path != null) {
          _recordingsByPage[pageIndex] = path;
        }
      });

      debugPrint('🛑 Recording stopped');

      debugPrint('Saved path: $path');

      if (path != null) {
        await _analyzeRecording(
          audioPath: path,
          expectedText: expectedText,
          pageIndex: pageIndex,
        );
      }
    } catch (e) {
      debugPrint('Recording stop error: $e');

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _isAnalyzing = false;
      });
    }
  }

  // ==========================================================
  // START / STOP BUTTON
  // ==========================================================

  Future<void> _toggleRecording(String expectedText) async {
    if (_isRecording) {
      await _stopRecording(expectedText);
    } else {
      await _startRecording();
    }
  }

  // ==========================================================
  // WHOLE BOOK SCORE
  // ==========================================================

  int _resultInt(Map<String, dynamic> result, String key) {
    final value = result[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic>? _calculateBookResult(int totalPages) {
    // Make sure every page has been analyzed.
    for (int i = 0; i < totalPages; i++) {
      if (!_assessmentByPage.containsKey(i)) {
        return null;
      }
    }

    int totalCorrect = 0;
    int totalSubstitutions = 0;
    int totalOmissions = 0;
    int totalAdditions = 0;
    int totalExpectedWords = 0;

    for (int i = 0; i < totalPages; i++) {
      final result = _assessmentByPage[i]!;

      final int correct = _resultInt(result, 'correct');

      final int substitutions = _resultInt(result, 'substitutions');

      final int omissions = _resultInt(result, 'omissions');

      final int additions = _resultInt(result, 'additions');

      totalCorrect += correct;

      totalSubstitutions += substitutions;

      totalOmissions += omissions;

      totalAdditions += additions;

      // Expected words =
      // correct + substituted + omitted.
      //
      // Additions are spoken extra words,
      // so they are errors but they are not
      // part of the expected story length.
      totalExpectedWords += correct + substitutions + omissions;
    }

    final int totalErrors =
        totalSubstitutions + totalOmissions + totalAdditions;

    double bookScore = 0.0;

    if (totalExpectedWords > 0) {
      bookScore = 100 * (1 - (totalErrors / totalExpectedWords));

      bookScore = bookScore.clamp(0.0, 100.0);
    }

    return {
      'book_score': bookScore,
      'correct': totalCorrect,
      'substitutions': totalSubstitutions,
      'omissions': totalOmissions,
      'additions': totalAdditions,
      'expected_words': totalExpectedWords,
      'total_errors': totalErrors,
    };
  }

  // ==========================================================
  // SAVE READING PROGRESS TO CHILD DOCUMENT
  // ==========================================================

  Future<void> _saveReadingProgress({
    required Map<String, dynamic> result,
    required int totalPages,
  }) async {
    final childRef = _childRef;

    if (childRef == null) {
      return;
    }

    final String levelKey = 'level_${widget.level}';

    final doc = await childRef.get();
    final data = doc.data();

    final Map<String, dynamic> currentProgress = Map<String, dynamic>.from(
      data?['readingProgress'] ?? {},
    );

    final Map<String, dynamic> currentLevelProgress = Map<String, dynamic>.from(
      currentProgress[levelKey] ?? {},
    );

    final Map<String, dynamic> oldStoryReading = Map<String, dynamic>.from(
      currentLevelProgress['storyReading'] ?? {},
    );

    final int oldCompletedCount =
        ((oldStoryReading['completedCount'] as num?)?.toInt() ?? 0);

    final double oldBestScore =
        ((oldStoryReading['bestScore'] as num?)?.toDouble() ?? 0.0);

    final bool wasCompleted = oldStoryReading['completed'] == true;

    final double currentScore = (result['book_score'] as num).toDouble();

    final bool isNewBest = !wasCompleted || currentScore > oldBestScore;

    final double bestScore = isNewBest ? currentScore : oldBestScore;

    final Map<String, dynamic> currentAttemptPages = {};

    for (int i = 0; i < totalPages; i++) {
      final Map<String, dynamic> page = _assessmentByPage[i]!;

      currentAttemptPages['page_${i + 1}'] = {
        'pageScore': page['page_score'],
        'correct': page['correct'],
        'substitutions': page['substitutions'],
        'omissions': page['omissions'],
        'additions': page['additions'],
        'expectedText': page['expected_text'],
        'recognizedText': page['recognized_text'],
        'alignment': page['alignment'],
        'savedAt': FieldValue.serverTimestamp(),
      };
    }

    // Start by preserving everything that already exists.
    final Map<String, dynamic> updatedStoryReading = Map<String, dynamic>.from(
      oldStoryReading,
    );

    updatedStoryReading['completed'] = true;
    updatedStoryReading['completedCount'] = oldCompletedCount + 1;
    updatedStoryReading['bookId'] = widget.bookId;
    updatedStoryReading['bookTitle'] = widget.title;
    updatedStoryReading['bestScore'] = double.parse(
      bestScore.toStringAsFixed(2),
    );
    updatedStoryReading['totalPages'] = totalPages;
    updatedStoryReading['lastCompletedAt'] = FieldValue.serverTimestamp();
    updatedStoryReading['updatedAt'] = FieldValue.serverTimestamp();

    if (isNewBest) {
      // Only replace the main saved result when this attempt is better.
      updatedStoryReading['lastScore'] = double.parse(
        currentScore.toStringAsFixed(2),
      );
      updatedStoryReading['correct'] = result['correct'];
      updatedStoryReading['substitutions'] = result['substitutions'];
      updatedStoryReading['omissions'] = result['omissions'];
      updatedStoryReading['additions'] = result['additions'];
      updatedStoryReading['totalErrors'] = result['total_errors'];
      updatedStoryReading['totalExpectedWords'] = result['expected_words'];
      updatedStoryReading['pageResults'] = currentAttemptPages;
      updatedStoryReading['bestCompletedAt'] = FieldValue.serverTimestamp();
    }

    // After finishing, use the BEST saved pages as the pages shown next
    // time the child opens the book. A lower reread never replaces them.
    final Map<String, dynamic> bestPages = Map<String, dynamic>.from(
      updatedStoryReading['pageResults'] ?? currentAttemptPages,
    );

    updatedStoryReading['currentPageResults'] = bestPages;

    currentLevelProgress['storyReading'] = updatedStoryReading;
    currentLevelProgress['updatedAt'] = FieldValue.serverTimestamp();
    currentProgress[levelKey] = currentLevelProgress;

    await childRef.set({
      'readingProgress': currentProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _finishBook(int totalPages) async {
    final result = _calculateBookResult(totalPages);

    if (result == null) {
      return;
    }

    // Save the completed book result in the selected child's document.
    try {
      await _saveReadingProgress(result: result, totalPages: totalPages);
      debugPrint('✅ Reading progress saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save reading progress: $e');

      return;
    }

    if (!mounted) return;

    final String? action = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BookResultPage(
          title: widget.title,
          coverPath: widget.coverPath,
          useOpenDyslexic: widget.useOpenDyslexic,
          score: (result['book_score'] as num).toDouble(),
          correct: result['correct'] as int,
          substitutions: result['substitutions'] as int,
          omissions: result['omissions'] as int,
          additions: result['additions'] as int,
          expectedWords: result['expected_words'] as int,
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'again') {
      setState(() {
        _currentPage = 0;

        _recordingsByPage.clear();

        _assessmentByPage.clear();
        _savedPages.clear();
      });
    }

    if (action == 'library') {
      Navigator.of(context).pop();
    }
  }

  // ==========================================================
  // CLEAN UP
  // ==========================================================

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      backgroundColor: ReadingPage.softCream,

      appBar: AppBar(
        backgroundColor: ReadingPage.softCream,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: ReadingPage.textDark,
          onPressed: _isRecording || _isAnalyzing
              ? null
              : () => Navigator.of(context).pop(),
        ),

        title: Text(
          widget.title,
          style: AppTypography.getStyle(
            useOpenDyslexic: widget.useOpenDyslexic,
            fontSize: R.text(16),
            fontWeight: FontWeight.w600,
            color: ReadingPage.textDark,
          ),
        ),
      ),

      body: _isLoadingSavedProgress
          ? const Center(
              child: CircularProgressIndicator(color: ReadingPage.primaryGreen),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reading_books')
                  .doc(widget.bookId)
                  .collection('pages')
                  .orderBy('page_number')
                  .snapshots(),

              builder: (context, pagesSnap) {
                if (pagesSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ReadingPage.primaryGreen,
                    ),
                  );
                }

                if (pagesSnap.hasError) {
                  return _ReaderMessage(
                    message: 'Could not load the story pages.',
                    useOpenDyslexic: widget.useOpenDyslexic,
                  );
                }

                final pages = pagesSnap.data?.docs ?? [];

                if (pages.isEmpty) {
                  return _ReaderMessage(
                    message: 'No pages were found for this book.',
                    useOpenDyslexic: widget.useOpenDyslexic,
                  );
                }

                final int safeCurrentPage = _currentPage.clamp(
                  0,
                  pages.length - 1,
                );

                final pageData = pages[safeCurrentPage].data();

                final String text = (pageData['text'] ?? '').toString();

                final String imagePath = (pageData['image_storage_path'] ?? '')
                    .toString();

                final Map<String, dynamic>? assessment =
                    _assessmentByPage[safeCurrentPage];

                final bool hasRecording =
                    _recordingsByPage.containsKey(safeCurrentPage) ||
                    assessment != null;

                final bool currentPageAssessed = assessment != null;
                final bool currentPageSaved = _savedPages.contains(
                  safeCurrentPage,
                );

                final bool isLastPage = safeCurrentPage == pages.length - 1;

                final bool allPagesReady = List.generate(
                  pages.length,
                  (index) =>
                      _assessmentByPage.containsKey(index) &&
                      _savedPages.contains(index),
                ).every((value) => value);

                return Column(
                  children: [
                    // =================================================
                    // PAGE INDICATOR
                    // =================================================
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        R.pagePad,
                        R.space(6),
                        R.pagePad,
                        R.space(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.symmetric(
                              horizontal: R.space(3),
                            ),
                            width: index == safeCurrentPage
                                ? R.space(18)
                                : R.space(7),
                            height: R.space(7),
                            decoration: BoxDecoration(
                              color: index == safeCurrentPage
                                  ? ReadingPage.primaryGreen
                                  : ReadingPage.primaryGreen.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(R.radius(20)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // STORY CONTENT
                    // =================================================
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: 1264 / 848,
                              child: imagePath.isEmpty
                                  ? Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.black26,
                                        ),
                                      ),
                                    )
                                  : _StorageImage(
                                      key: ValueKey(imagePath),
                                      storagePath: imagePath,
                                      fit: BoxFit.cover,
                                    ),
                            ),

                            SizedBox(height: R.space(24)),

                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.pagePad + R.space(8),
                              ),
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                style: AppTypography.getStyle(
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  fontSize: R.text(22),
                                  fontWeight: FontWeight.w500,
                                  color: ReadingPage.textDark,
                                  height: 1.45,
                                ),
                              ),
                            ),

                            SizedBox(height: R.space(28)),

                            // =================================================
                            // RECORDING BUTTON
                            // =================================================
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.pagePad,
                              ),
                              child: SizedBox(
                                height: R.space(54),
                                child: ElevatedButton.icon(
                                  onPressed: _isAnalyzing
                                      ? null
                                      : () => _toggleRecording(text),

                                  icon: _isAnalyzing
                                      ? SizedBox(
                                          width: R.icon(18),
                                          height: R.icon(18),
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                        )
                                      : Icon(
                                          _isRecording
                                              ? Icons.stop_circle_rounded
                                              : Icons.mic_rounded,
                                        ),

                                  label: Text(
                                    _isAnalyzing
                                        ? 'Analyzing...'
                                        : _isRecording
                                        ? 'Stop Recording'
                                        : hasRecording
                                        ? 'Record Again'
                                        : 'Start Recording',
                                    style: AppTypography.getStyle(
                                      useOpenDyslexic: widget.useOpenDyslexic,
                                      fontSize: R.text(15),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRecording
                                        ? Colors.redAccent
                                        : ReadingPage.primaryGreen,
                                    disabledBackgroundColor: ReadingPage
                                        .primaryGreen
                                        .withOpacity(0.55),
                                    disabledForegroundColor: Colors.white,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        R.radius(18),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // =================================================
                            // ANALYZING
                            // =================================================
                            if (_isAnalyzing) ...[
                              SizedBox(height: R.space(10)),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: R.icon(15),
                                    height: R.icon(15),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ReadingPage.primaryGreen,
                                    ),
                                  ),

                                  SizedBox(width: R.space(7)),

                                  Text(
                                    'Analyzing reading...',
                                    style: AppTypography.getStyle(
                                      useOpenDyslexic: widget.useOpenDyslexic,
                                      fontSize: R.text(12),
                                      fontWeight: FontWeight.w500,
                                      color: ReadingPage.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // =================================================
                            // RECORDING SAVED
                            // =================================================
                            if (assessment != null &&
                                !_isRecording &&
                                !_isAnalyzing) ...[
                              SizedBox(height: R.space(10)),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    currentPageSaved
                                        ? Icons.check_circle_rounded
                                        : Icons.cloud_off_rounded,
                                    color: currentPageSaved
                                        ? ReadingPage.primaryGreen
                                        : Colors.redAccent,
                                    size: R.icon(17),
                                  ),

                                  SizedBox(width: R.space(5)),

                                  Text(
                                    currentPageSaved
                                        ? 'Result saved ✓'
                                        : 'Result not saved — please record again',
                                    style: AppTypography.getStyle(
                                      useOpenDyslexic: widget.useOpenDyslexic,
                                      fontSize: R.text(12),
                                      fontWeight: FontWeight.w500,
                                      color: currentPageSaved
                                          ? ReadingPage.primaryGreen
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // =================================================
                            // DETAILED PAGE RESULT
                            // =================================================
                            if (assessment != null && !_isAnalyzing) ...[
                              SizedBox(height: R.space(12)),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: R.pagePad,
                                ),
                                child: _PageReadingResultCard(
                                  assessment: assessment,
                                  fallbackExpectedText: text,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                ),
                              ),
                            ],

                            SizedBox(height: R.space(22)),
                          ],
                        ),
                      ),
                    ),

                    // =================================================
                    // BACK / NEXT / FINISH
                    // =================================================
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        R.pagePad,
                        R.space(4),
                        R.pagePad,
                        R.safeBottom + R.space(14),
                      ),
                      child: Row(
                        children: [
                          // BACK
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  safeCurrentPage == 0 ||
                                      _isRecording ||
                                      _isAnalyzing
                                  ? null
                                  : () {
                                      setState(() {
                                        _currentPage = safeCurrentPage - 1;
                                      });
                                    },

                              icon: const Icon(Icons.arrow_back_rounded),

                              label: const Text('Back'),

                              style: OutlinedButton.styleFrom(
                                foregroundColor: ReadingPage.primaryGreen,
                                side: BorderSide(
                                  color: ReadingPage.primaryGreen.withOpacity(
                                    0.45,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: R.space(13),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(18),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: R.space(12)),

                          // NEXT / FINISH
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isRecording ||
                                      _isAnalyzing ||
                                      !currentPageAssessed ||
                                      !currentPageSaved ||
                                      (isLastPage && !allPagesReady)
                                  ? null
                                  : isLastPage
                                  ? () => _finishBook(pages.length)
                                  : () {
                                      setState(() {
                                        _currentPage = safeCurrentPage + 1;
                                      });
                                    },

                              icon: Icon(
                                isLastPage
                                    ? Icons.auto_awesome_rounded
                                    : Icons.arrow_forward_rounded,
                              ),

                              label: Text(isLastPage ? 'Finish Book' : 'Next'),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: ReadingPage.primaryGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: ReadingPage
                                    .primaryGreen
                                    .withOpacity(0.25),
                                disabledForegroundColor: Colors.white70,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: R.space(13),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ============================================================
// DETAILED PAGE RESULT CARD
// ============================================================

class _PageReadingResultCard extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final String fallbackExpectedText;
  final bool useOpenDyslexic;

  const _PageReadingResultCard({
    required this.assessment,
    required this.fallbackExpectedText,
    required this.useOpenDyslexic,
  });

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double rawScore = _toDouble(assessment['page_score']);
    final double score = rawScore < 0
        ? 0.0
        : rawScore > 100
        ? 100.0
        : rawScore;
    final int correct = _toInt(assessment['correct']);
    final int substitutions = _toInt(assessment['substitutions']);
    final int omissions = _toInt(assessment['omissions']);
    final int additions = _toInt(assessment['additions']);

    final int expectedWords = correct + substitutions + omissions;

    final String expectedText =
        (assessment['expected_text'] ?? fallbackExpectedText).toString().trim();

    final String recognizedText = (assessment['recognized_text'] ?? '')
        .toString()
        .trim();

    String feedback;

    if (score >= 90) {
      feedback = 'Excellent reading! You read this page very accurately.';
    } else if (score >= 75) {
      feedback = 'Great job! A little practice can make it even stronger.';
    } else if (score >= 50) {
      feedback =
          'Good effort! Try the page again if you want to improve your score.';
    } else {
      feedback = 'Keep practicing! Reading the page again can help.';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.space(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(22)),
        border: Border.all(color: ReadingPage.primaryGreen.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: R.icon(42),
                height: R.icon(42),
                decoration: BoxDecoration(
                  color: ReadingPage.primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: ReadingPage.primaryGreen,
                  size: R.icon(22),
                ),
              ),
              SizedBox(width: R.space(10)),
              Expanded(
                child: Text(
                  'Page Result',
                  style: AppTypography.getStyle(
                    useOpenDyslexic: useOpenDyslexic,
                    fontSize: R.text(16),
                    fontWeight: FontWeight.w700,
                    color: ReadingPage.textDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: R.space(12),
                  vertical: R.space(7),
                ),
                decoration: BoxDecoration(
                  color: ReadingPage.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(R.radius(20)),
                ),
                child: Text(
                  '${score.round()}%',
                  style: AppTypography.getStyle(
                    useOpenDyslexic: useOpenDyslexic,
                    fontSize: R.text(16),
                    fontWeight: FontWeight.w700,
                    color: ReadingPage.primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: R.space(12)),

          Text(
            feedback,
            textAlign: TextAlign.center,
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(11.5),
              fontWeight: FontWeight.w500,
              color: ReadingPage.textDark.withOpacity(0.62),
              height: 1.4,
            ),
          ),

          SizedBox(height: R.space(14)),

          Row(
            children: [
              Expanded(
                child: _PageResultStat(
                  icon: Icons.check_circle_rounded,
                  label: 'Correct words',
                  value: correct,
                  color: ReadingPage.primaryGreen,
                  backgroundColor: const Color(0xFFEAF6F0),
                  useOpenDyslexic: useOpenDyslexic,
                ),
              ),
              SizedBox(width: R.space(8)),
              Expanded(
                child: _PageResultStat(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Changed words',
                  value: substitutions,
                  color: const Color(0xFFF0A24A),
                  backgroundColor: const Color(0xFFFFF5E8),
                  useOpenDyslexic: useOpenDyslexic,
                ),
              ),
            ],
          ),

          SizedBox(height: R.space(8)),

          Row(
            children: [
              Expanded(
                child: _PageResultStat(
                  icon: Icons.remove_circle_outline_rounded,
                  label: 'Missed words',
                  value: omissions,
                  color: const Color(0xFFE36E6E),
                  backgroundColor: const Color(0xFFFFEEEE),
                  useOpenDyslexic: useOpenDyslexic,
                ),
              ),
              SizedBox(width: R.space(8)),
              Expanded(
                child: _PageResultStat(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Extra words',
                  value: additions,
                  color: const Color(0xFF7789D8),
                  backgroundColor: const Color(0xFFEEF1FF),
                  useOpenDyslexic: useOpenDyslexic,
                ),
              ),
            ],
          ),

          SizedBox(height: R.space(14)),

          _PageTextResultSection(
            icon: Icons.menu_book_rounded,
            title: 'Story Text',
            text: expectedText.isEmpty
                ? 'No story text available.'
                : expectedText,
            useOpenDyslexic: useOpenDyslexic,
          ),

          SizedBox(height: R.space(10)),

          _PageTextResultSection(
            icon: Icons.hearing_rounded,
            title: 'What Lexia Heard',
            text: recognizedText.isEmpty
                ? 'No words were recognized.'
                : recognizedText,
            useOpenDyslexic: useOpenDyslexic,
          ),

          SizedBox(height: R.space(12)),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: R.icon(15),
                color: ReadingPage.textDark.withOpacity(0.45),
              ),
              SizedBox(width: R.space(5)),
              Flexible(
                child: Text(
                  '$correct correct out of $expectedWords expected words'
                  '${additions > 0 ? ' • $additions extra spoken' : ''}',
                  textAlign: TextAlign.center,
                  style: AppTypography.getStyle(
                    useOpenDyslexic: useOpenDyslexic,
                    fontSize: R.text(10.5),
                    fontWeight: FontWeight.w500,
                    color: ReadingPage.textDark.withOpacity(0.50),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: R.space(8)),

          Text(
            'You can record again or continue to the next page.',
            textAlign: TextAlign.center,
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(10.5),
              fontWeight: FontWeight.w500,
              color: ReadingPage.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final Color backgroundColor;
  final bool useOpenDyslexic;

  const _PageResultStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.useOpenDyslexic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(5),
        vertical: R.space(9),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(R.radius(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: R.icon(18), color: color),
          SizedBox(height: R.space(3)),
          Text(
            '$value',
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(15),
              fontWeight: FontWeight.w700,
              color: ReadingPage.textDark,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(9.5),
              fontWeight: FontWeight.w500,
              color: ReadingPage.textDark.withOpacity(0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTextResultSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final bool useOpenDyslexic;

  const _PageTextResultSection({
    required this.icon,
    required this.title,
    required this.text,
    required this.useOpenDyslexic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.space(11)),
      decoration: BoxDecoration(
        color: ReadingPage.softCream.withOpacity(0.72),
        borderRadius: BorderRadius.circular(R.radius(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: R.icon(15), color: ReadingPage.primaryGreen),
              SizedBox(width: R.space(6)),
              Text(
                title,
                style: AppTypography.getStyle(
                  useOpenDyslexic: useOpenDyslexic,
                  fontSize: R.text(10.5),
                  fontWeight: FontWeight.w700,
                  color: ReadingPage.textDark.withOpacity(0.72),
                ),
              ),
            ],
          ),
          SizedBox(height: R.space(6)),
          Text(
            text,
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(11),
              fontWeight: FontWeight.w400,
              color: ReadingPage.textDark.withOpacity(0.68),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FINAL BOOK RESULT PAGE
// ============================================================

class BookResultPage extends StatefulWidget {
  final String title;
  final String coverPath;
  final bool useOpenDyslexic;

  final double score;

  final int correct;
  final int substitutions;
  final int omissions;
  final int additions;
  final int expectedWords;

  const BookResultPage({
    super.key,
    required this.title,
    required this.coverPath,
    required this.useOpenDyslexic,
    required this.score,
    required this.correct,
    required this.substitutions,
    required this.omissions,
    required this.additions,
    required this.expectedWords,
  });

  @override
  State<BookResultPage> createState() => _BookResultPageState();
}

class _BookResultPageState extends State<BookResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;

  late final Animation<double> _scaleAnimation;

  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _resultTitle {
    if (widget.score >= 90) {
      return 'Amazing Reading! 🌟';
    }

    if (widget.score >= 75) {
      return 'Great Job! ✨';
    }

    if (widget.score >= 60) {
      return 'Good Effort! 👍';
    }

    return 'Keep Practicing! 🌱';
  }

  String get _resultMessage {
    if (widget.score >= 90) {
      return 'You read the story very accurately. Keep up the amazing work!';
    }

    if (widget.score >= 75) {
      return 'You did a great job! Keep practicing the tricky words.';
    }

    if (widget.score >= 60) {
      return 'Nice work finishing the story. A little more practice will help!';
    }

    return 'Good effort! Try reading the story again and keep practicing.';
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double safeScore = widget.score.clamp(0.0, 100.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3FAF6), Color(0xFFFFFDFB), Color(0xFFFFF7F4)],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: EdgeInsets.fromLTRB(
              R.pagePad,
              R.space(18),
              R.pagePad,
              R.space(24),
            ),

            child: FadeTransition(
              opacity: _fadeAnimation,

              child: SlideTransition(
                position: _slideAnimation,

                child: Column(
                  children: [
                    // --------------------------------------------
                    // DECORATIVE STARS
                    // --------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: R.icon(18),
                          color: const Color(0xFFF1B74A),
                        ),

                        SizedBox(width: R.space(8)),

                        Icon(
                          Icons.star_rounded,
                          size: R.icon(26),
                          color: const Color(0xFFF1B74A),
                        ),

                        SizedBox(width: R.space(8)),

                        Icon(
                          Icons.auto_awesome_rounded,
                          size: R.icon(18),
                          color: const Color(0xFFF1B74A),
                        ),
                      ],
                    ),

                    SizedBox(height: R.space(12)),

                    // --------------------------------------------
                    // TITLE
                    // --------------------------------------------
                    Text(
                      'Story Complete!',
                      textAlign: TextAlign.center,
                      style: AppTypography.getStyle(
                        useOpenDyslexic: widget.useOpenDyslexic,
                        fontSize: R.text(25),
                        fontWeight: FontWeight.w700,
                        color: ReadingPage.textDark,
                      ),
                    ),

                    SizedBox(height: R.space(6)),

                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.getStyle(
                        useOpenDyslexic: widget.useOpenDyslexic,
                        fontSize: R.text(14),
                        fontWeight: FontWeight.w500,
                        color: ReadingPage.textDark.withOpacity(0.55),
                      ),
                    ),

                    SizedBox(height: R.space(22)),

                    // --------------------------------------------
                    // ANIMATED BOOK COVER
                    // --------------------------------------------
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: R.icon(118),
                        height: R.space(154),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(R.radius(12)),
                            bottomRight: Radius.circular(R.radius(12)),
                            topLeft: Radius.circular(R.radius(4)),
                            bottomLeft: Radius.circular(R.radius(4)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ReadingPage.textDark.withOpacity(0.14),
                              blurRadius: 18,
                              offset: const Offset(3, 8),
                            ),
                          ],
                        ),

                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.coverPath.isNotEmpty)
                              _StorageImage(
                                storagePath: widget.coverPath,
                                fit: BoxFit.cover,
                              )
                            else
                              Center(
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: R.icon(45),
                                  color: ReadingPage.primaryGreen.withOpacity(
                                    0.35,
                                  ),
                                ),
                              ),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: R.space(7),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.16),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: R.space(26)),

                    // --------------------------------------------
                    // RESULT MESSAGE
                    // --------------------------------------------
                    Text(
                      _resultTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.getStyle(
                        useOpenDyslexic: widget.useOpenDyslexic,
                        fontSize: R.text(20),
                        fontWeight: FontWeight.w700,
                        color: ReadingPage.textDark,
                      ),
                    ),

                    SizedBox(height: R.space(8)),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: R.space(14)),
                      child: Text(
                        _resultMessage,
                        textAlign: TextAlign.center,
                        style: AppTypography.getStyle(
                          useOpenDyslexic: widget.useOpenDyslexic,
                          fontSize: R.text(13),
                          fontWeight: FontWeight.w400,
                          color: ReadingPage.textDark.withOpacity(0.62),
                          height: 1.45,
                        ),
                      ),
                    ),

                    SizedBox(height: R.space(24)),

                    // --------------------------------------------
                    // ANIMATED SCORE
                    // --------------------------------------------
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: safeScore),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,

                      builder: (context, value, child) {
                        return SizedBox(
                          width: R.icon(145),
                          height: R.icon(145),

                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: R.icon(135),
                                height: R.icon(135),
                                child: CircularProgressIndicator(
                                  value: value / 100,
                                  strokeWidth: R.space(10),
                                  backgroundColor: ReadingPage.primaryGreen
                                      .withOpacity(0.12),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        ReadingPage.primaryGreen,
                                      ),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),

                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${value.round()}%',
                                    style: AppTypography.getStyle(
                                      useOpenDyslexic: widget.useOpenDyslexic,
                                      fontSize: R.text(28),
                                      fontWeight: FontWeight.w700,
                                      color: ReadingPage.primaryGreen,
                                    ),
                                  ),

                                  SizedBox(height: R.space(2)),

                                  Text(
                                    'Reading Score',
                                    style: AppTypography.getStyle(
                                      useOpenDyslexic: widget.useOpenDyslexic,
                                      fontSize: R.text(10),
                                      fontWeight: FontWeight.w500,
                                      color: ReadingPage.textDark.withOpacity(
                                        0.55,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: R.space(26)),

                    // --------------------------------------------
                    // READING SUMMARY CARD
                    // --------------------------------------------
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(R.space(18)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(R.radius(24)),
                        border: Border.all(
                          color: ReadingPage.primaryGreen.withOpacity(0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ReadingPage.textDark.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          Text(
                            'Your Reading',
                            style: AppTypography.getStyle(
                              useOpenDyslexic: widget.useOpenDyslexic,
                              fontSize: R.text(16),
                              fontWeight: FontWeight.w700,
                              color: ReadingPage.textDark,
                            ),
                          ),

                          SizedBox(height: R.space(16)),

                          Row(
                            children: [
                              Expanded(
                                child: _ResultStatCard(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Correct words',
                                  value: widget.correct,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: ReadingPage.primaryGreen,
                                  backgroundColor: const Color(0xFFEAF6F0),
                                ),
                              ),

                              SizedBox(width: R.space(10)),

                              Expanded(
                                child: _ResultStatCard(
                                  icon: Icons.swap_horiz_rounded,
                                  label: 'Changed words',
                                  value: widget.substitutions,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: const Color(0xFFF0A24A),
                                  backgroundColor: const Color(0xFFFFF5E8),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: R.space(10)),

                          Row(
                            children: [
                              Expanded(
                                child: _ResultStatCard(
                                  icon: Icons.remove_circle_outline_rounded,
                                  label: 'Missed words',
                                  value: widget.omissions,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: const Color(0xFFE36E6E),
                                  backgroundColor: const Color(0xFFFFEEEE),
                                ),
                              ),

                              SizedBox(width: R.space(10)),

                              Expanded(
                                child: _ResultStatCard(
                                  icon: Icons.add_circle_outline_rounded,
                                  label: 'Extra words',
                                  value: widget.additions,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: const Color(0xFF7789D8),
                                  backgroundColor: const Color(0xFFEEF1FF),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: R.space(15)),

                          Divider(
                            color: ReadingPage.textDark.withOpacity(0.08),
                          ),

                          SizedBox(height: R.space(8)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: R.icon(17),
                                color: ReadingPage.primaryGreen,
                              ),

                              SizedBox(width: R.space(7)),

                              Text(
                                '${widget.expectedWords} words in this story',
                                style: AppTypography.getStyle(
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  fontSize: R.text(12),
                                  fontWeight: FontWeight.w500,
                                  color: ReadingPage.textDark.withOpacity(0.58),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: R.space(24)),

                    // --------------------------------------------
                    // READ AGAIN
                    // --------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: R.space(54),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop('again');
                        },

                        icon: const Icon(Icons.replay_rounded),

                        label: Text(
                          'Read Again',
                          style: AppTypography.getStyle(
                            useOpenDyslexic: widget.useOpenDyslexic,
                            fontSize: R.text(15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReadingPage.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(R.radius(18)),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: R.space(10)),

                    // --------------------------------------------
                    // BACK TO LIBRARY
                    // --------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: R.space(52),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop('library');
                        },

                        icon: const Icon(Icons.local_library_rounded),

                        label: Text(
                          'Back to Library',
                          style: AppTypography.getStyle(
                            useOpenDyslexic: widget.useOpenDyslexic,
                            fontSize: R.text(14),
                            fontWeight: FontWeight.w600,
                            color: ReadingPage.primaryGreen,
                          ),
                        ),

                        style: OutlinedButton.styleFrom(
                          foregroundColor: ReadingPage.primaryGreen,
                          side: BorderSide(
                            color: ReadingPage.primaryGreen.withOpacity(0.40),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(R.radius(18)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RESULT STAT CARD
// ============================================================

class _ResultStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final bool useOpenDyslexic;
  final Color iconColor;
  final Color backgroundColor;

  const _ResultStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.useOpenDyslexic,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: R.space(10),
        vertical: R.space(13),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(R.radius(16)),
      ),

      child: Column(
        children: [
          Icon(icon, color: iconColor, size: R.icon(22)),

          SizedBox(height: R.space(6)),

          Text(
            '$value',
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(18),
              fontWeight: FontWeight.w700,
              color: ReadingPage.textDark,
            ),
          ),

          SizedBox(height: R.space(2)),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(9.5),
              fontWeight: FontWeight.w500,
              color: ReadingPage.textDark.withOpacity(0.60),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FIREBASE STORAGE IMAGE
// ============================================================

class _StorageImage extends StatelessWidget {
  final String storagePath;
  final BoxFit fit;

  const _StorageImage({
    super.key,
    required this.storagePath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(storagePath).getDownloadURL(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ReadingPage.primaryGreen,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.black26),
          );
        }

        return Image.network(
          snapshot.data!,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.black26),
          ),
        );
      },
    );
  }
}

// ============================================================
// READER MESSAGE
// ============================================================

class _ReaderMessage extends StatelessWidget {
  final String message;
  final bool useOpenDyslexic;

  const _ReaderMessage({required this.message, required this.useOpenDyslexic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(R.pagePad),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.getStyle(
            useOpenDyslexic: useOpenDyslexic,
            fontSize: R.text(14),
            color: ReadingPage.textDark.withOpacity(0.65),
          ),
        ),
      ),
    );
  }
}
