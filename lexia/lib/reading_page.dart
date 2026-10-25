import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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
  bool _isFinishingBook = false;

  final Map<int, String> _recordingsByPage = {};

  final Map<int, Map<String, dynamic>> _assessmentByPage = {};

  // UI: the latest actual recording, even if its score is lower.
  // Book scoring / persistence: independent best recording of each page.
  // Never replace the best page result with a worse latest attempt.
  final Map<int, Map<String, dynamic>> _latestAssessmentByPage = {};

  // This book run ONLY: latest recordings override historical best pages
  // for Finish Book; untouched pages use their best saved records.
  final Map<int, Map<String, dynamic>> _currentAttemptByPage = {};

  // Tracks which page assessments are safely stored in Firestore.
  final Set<int> _savedPages = {};

  // Saved page results are loaded from Firestore when the book opens.
  bool _isLoadingSavedProgress = true;

  // A completed book can be browsed without making another recording.
  bool _hasCompletedBook = false;

  // Colors taken from the current story picture. They tint the whole
  // reading screen so a small picture blends into a matching gradient.
  Color _tintTop = ReadingPage.softCream;
  Color _tintBottom = ReadingPage.softCream;

  void _onPictureColors(Color top, Color bottom) {
    if (!mounted) return;
    if (top == _tintTop && bottom == _tintBottom) return;
    setState(() {
      _tintTop = top;
      _tintBottom = bottom;
    });
  }

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

        // Legacy results do not contain weighted points. They cannot be
        // safely aggregated with the new scoring method; rerecord that page.
        if (saved['earnedPoints'] is! num ||
            saved['availablePoints'] is! num ||
            (saved['availablePoints'] as num) <= 0) {
          debugPrint('Page $pageNumber needs a new weighted assessment.');
          continue;
        }

        loadedResults[pageNumber - 1] = {
          'earned_points': saved['earnedPoints'],
          'available_points': saved['availablePoints'],
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

      // Restore an unfinished current attempt if the child left the book
      // midway through it. Finished book runs are not treated as new attempts.
      final resumedAttempt = <int, Map<String, dynamic>>{};
      if (storyReading['attemptInProgress'] == true) {
        final savedCurrent = Map<String, dynamic>.from(
          storyReading['currentAttemptPageResults'] ?? {},
        );
        for (final entry in savedCurrent.entries) {
          final pageNumber = int.tryParse(entry.key.replaceFirst('page_', ''));
          if (pageNumber == null || entry.value is! Map) continue;
          final saved = Map<String, dynamic>.from(entry.value as Map);
          if (saved['earnedPoints'] is! num ||
              saved['availablePoints'] is! num) continue;
          resumedAttempt[pageNumber - 1] = {
            'earned_points': saved['earnedPoints'],
            'available_points': saved['availablePoints'],
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
      }

      if (!mounted) return;

      setState(() {
        _assessmentByPage.addAll(loadedResults);
        _latestAssessmentByPage.addAll(loadedResults);
        _latestAssessmentByPage.addAll(resumedAttempt);
        _currentAttemptByPage.addAll(resumedAttempt);
        _savedPages.addAll(resumedAttempt.keys);
        _hasCompletedBook = storyReading['completed'] == true;
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

  Map<String, dynamic> _pageForFirestore(Map<String, dynamic> result) {
    return {
      'pageScore': result['page_score'],
      'earnedPoints': result['earned_points'],
      'availablePoints': result['available_points'],
      'correct': result['correct'],
      'substitutions': result['substitutions'],
      'omissions': result['omissions'],
      'additions': result['additions'],
      'expectedText': result['expected_text'],
      'recognizedText': result['recognized_text'],
      'alignment': result['alignment'],
      'savedAt': FieldValue.serverTimestamp(),
    };
  }

  // Save EVERY current recording, including a worse one. Independently keep
  // the highest ever page result in currentPageResults.
  Future<void> _savePageResult({
    required int pageIndex,
    required Map<String, dynamic> result,
  }) async {
    final childRef = _childRef;
    if (childRef == null) throw StateError('Child profile not found.');

    final levelKey = 'level_${widget.level}';
    final doc = await childRef.get();
    final data = doc.data();
    final progress = Map<String, dynamic>.from(data?['readingProgress'] ?? {});
    final level = Map<String, dynamic>.from(progress[levelKey] ?? {});
    final story = Map<String, dynamic>.from(level['storyReading'] ?? {});

    // For older children, migrate their saved page records before removing
    // the redundant best-book snapshot.
    if (story['currentPageResults'] is! Map ||
        (story['currentPageResults'] as Map).isEmpty) {
      final legacyPages = story['pageResults'];
      if (legacyPages is Map) {
        story['currentPageResults'] = Map<String, dynamic>.from(legacyPages);
      }
    }

    // Remove duplicate/obsolete fields from older versions as the child
    // records new pages. Their values are no longer needed for comparisons.
    for (final key in <String>[
      'lastAttemptPageResults', 'lastAttemptScore',
      'lastAttemptEarnedPoints', 'lastAttemptAvailablePoints',
      'pageResults', 'earnedPoints', 'availablePoints',
      'correct', 'substitutions', 'omissions', 'additions',
      'totalErrors', 'totalExpectedWords', 'bestCompletedAt',
      'lastPageUpdated', 'totalPages',
    ]) {
      story.remove(key);
    }

    // Best page records: never downgrade them because of a lower retry.
    final bestPages = Map<String, dynamic>.from(
      story['currentPageResults'] ?? {},
    );
    final pageKey = 'page_${pageIndex + 1}';
    final previous = bestPages[pageKey];
    final previousScore = previous is Map &&
            previous['earnedPoints'] is num &&
            previous['availablePoints'] is num
        ? (previous['pageScore'] as num?)?.toDouble() ?? -1.0
        : -1.0;
    final best = _assessmentByPage[pageIndex]!;
    final bestScore = (best['page_score'] as num).toDouble();
    if (bestScore > previousScore) {
      bestPages[pageKey] = _pageForFirestore(best);
    }

    // Current attempt is separate from the best-page storage. Reconstruct
    // from session state so old attempts cannot leak into a new book run.
    final attemptPages = <String, dynamic>{};
    for (final entry in _currentAttemptByPage.entries) {
      attemptPages['page_${entry.key + 1}'] =
          _pageForFirestore(entry.value);
    }

    story['bookId'] = widget.bookId;
    story['bookTitle'] = widget.title;
    story['currentPageResults'] = bestPages;
    story['currentAttemptPageResults'] = attemptPages;
    story['attemptInProgress'] = true;
    story['updatedAt'] = FieldValue.serverTimestamp();
    story.putIfAbsent('completed', () => false);
    level['storyReading'] = story;
    level['updatedAt'] = FieldValue.serverTimestamp();
    progress[levelKey] = level;

    // Replace the story map instead of deeply merging it. This prevents
    // deprecated Firestore keys from returning after migration.
    await childRef.update({
      'readingProgress.$levelKey.storyReading': story,
      'readingProgress.$levelKey.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Saved latest Page ${pageIndex + 1} AND best page separately');
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
      // New attempt is always displayed and always participates in the
      // CURRENT book score, even when it is below a previous best.
      final previousBest = _assessmentByPage[pageIndex];
      final newScore = (result['page_score'] as num).toDouble();
      final previousScore =
          (previousBest?['page_score'] as num?)?.toDouble() ?? -1.0;
      final improved = previousBest == null || newScore > previousScore;

      setState(() {
        _latestAssessmentByPage[pageIndex] = result;
        _currentAttemptByPage[pageIndex] = result;
        if (improved) _assessmentByPage[pageIndex] = result;
        _savedPages.remove(pageIndex);
      });

      try {
        // Persist a lower current attempt too; it must not disappear from
        // Firestore just because the child scored higher before.
        await _savePageResult(pageIndex: pageIndex, result: result);
        if (mounted) setState(() => _savedPages.add(pageIndex));
      } catch (e) {
        debugPrint('Failed to save latest Page ${pageIndex + 1}: $e');
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

  // On Finish Book, use this visit's recording for a page if one exists.
  // Otherwise use the independently saved BEST result for that page.
  Map<String, dynamic>? _pageUsedForFinish(int index) =>
      _currentAttemptByPage[index] ?? _assessmentByPage[index];

  bool _hasAllBookPageResults(int totalPages) =>
      totalPages == 3 &&
      List.generate(totalPages, (index) {
        final page = _pageUsedForFinish(index);
        return page != null &&
            page['earned_points'] is num &&
            page['available_points'] is num &&
            (page['available_points'] as num) > 0 &&
            (!_currentAttemptByPage.containsKey(index) ||
                _savedPages.contains(index));
      }).every((ready) => ready);

  Future<Map<String, dynamic>> _calculateBookResult(int totalPages) async {
    if (totalPages != 3) {
      throw StateError('A book assessment requires exactly three pages.');
    }

    final List<Map<String, dynamic>> pages = [];
    int totalCorrect = 0;
    int totalSubstitutions = 0;
    int totalOmissions = 0;
    int totalAdditions = 0;
    int totalExpectedWords = 0;

    for (int i = 0; i < totalPages; i++) {
      final page = _pageUsedForFinish(i);
      if (page == null ||
          page['earned_points'] is! num ||
          page['available_points'] is! num) {
        throw StateError('Page ${i + 1} needs a weighted assessment.');
      }
      final double available = (page['available_points'] as num).toDouble();
      final double earned = (page['earned_points'] as num).toDouble();
      if (available <= 0 || earned < 0 || earned > available) {
        throw StateError('Invalid weighted points for page ${i + 1}.');
      }

      pages.add({
        'page_number': i + 1,
        'earned_points': earned,
        'available_points': available,
      });
      final correct = _resultInt(page, 'correct');
      final substitutions = _resultInt(page, 'substitutions');
      final omissions = _resultInt(page, 'omissions');
      totalCorrect += correct;
      totalSubstitutions += substitutions;
      totalOmissions += omissions;
      totalAdditions += _resultInt(page, 'additions');
      totalExpectedWords += correct + substitutions + omissions;
    }

    // Let the deployed Python score_book() do the aggregation.
    final uri = Uri.parse(
      'https://lexia-asr-100861482313.me-central1.run.app/book-assessment',
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pages': pages}),
    );
    if (response.statusCode != 200) {
      throw Exception('Book scoring failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['book_score_percent'] is! num) {
      throw const FormatException('Invalid book assessment response.');
    }
    final bookScore = (decoded['book_score_percent'] as num).toDouble();
    if (!bookScore.isFinite || bookScore < 0 || bookScore > 100) {
      throw const FormatException('Invalid book percentage.');
    }

    return {
      'book_score': bookScore,
      'earned_points': decoded['earned_points'],
      'available_points': decoded['available_points'],
      'correct': totalCorrect,
      'substitutions': totalSubstitutions,
      'omissions': totalOmissions,
      'additions': totalAdditions,
      'expected_words': totalExpectedWords,
      'total_errors': totalSubstitutions + totalOmissions + totalAdditions,
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

    // A historical unweighted best score must not be compared with weighted_v1.
    final bool sameScoringVersion =
        oldStoryReading['scoringVersion'] == 'weighted_v1';
    final double oldBestScore = sameScoringVersion
        ? ((oldStoryReading['bestScore'] as num?)?.toDouble() ?? 0.0)
        : 0.0;

    final double currentScore = (result['book_score'] as num).toDouble();

    // The first completed weighted book is a new baseline, even if it is 0%.
    final bool isNewBest = !sameScoringVersion ||
        oldStoryReading['bestScore'] is! num ||
        currentScore > oldBestScore;

    final double bestScore = isNewBest ? currentScore : oldBestScore;

    // Keep only the fields needed for scoring and progress. Old redundant
    // snapshots and counters are intentionally excluded during migration.
    final Map<String, dynamic> updatedStoryReading = {};

    if (!sameScoringVersion && oldStoryReading['bestScore'] is num) {
      updatedStoryReading['legacyBestScore'] = oldStoryReading['bestScore'];
    }
    updatedStoryReading['completed'] = true;
    updatedStoryReading['scoringVersion'] = 'weighted_v1';
    // Always save the latest completed score; bestScore is never reduced.
    updatedStoryReading['lastScore'] = double.parse(
      currentScore.toStringAsFixed(2),
    );
    updatedStoryReading['completedCount'] = oldCompletedCount + 1;
    updatedStoryReading['bookId'] = widget.bookId;
    updatedStoryReading['bookTitle'] = widget.title;
    updatedStoryReading['bestScore'] = double.parse(
      bestScore.toStringAsFixed(2),
    );
    updatedStoryReading['lastCompletedAt'] = FieldValue.serverTimestamp();
    updatedStoryReading['updatedAt'] = FieldValue.serverTimestamp();

    // Keep independent best pages separate from this completed attempt.
    // A lower reread must never overwrite a higher individual page record.
    final bestPageRecords = Map<String, dynamic>.from(
      oldStoryReading['currentPageResults'] ?? {},
    );
    for (int i = 0; i < totalPages; i++) {
      final best = _assessmentByPage[i];
      if (best == null) continue;
      final key = 'page_${i + 1}';
      final old = bestPageRecords[key];
      final oldScore = old is Map && old['earnedPoints'] is num
          ? (old['pageScore'] as num?)?.toDouble() ?? -1.0
          : -1.0;
      if ((best['page_score'] as num).toDouble() > oldScore) {
        bestPageRecords[key] = _pageForFirestore(best);
      }
    }
    updatedStoryReading['currentPageResults'] = bestPageRecords;

    // Finished attempts need no page snapshot: the latest book percentage
    // is in lastScore, and best individual pages remain in currentPageResults.
    // A future recording creates a fresh temporary current attempt.
    updatedStoryReading['attemptInProgress'] = false;

    currentLevelProgress['storyReading'] = updatedStoryReading;
    currentLevelProgress['updatedAt'] = FieldValue.serverTimestamp();
    currentProgress[levelKey] = currentLevelProgress;

    // Replace the whole story map so old lastAttempt*/pageResults fields
    // are actually deleted, rather than left behind by a deep merge.
    await childRef.update({
      'readingProgress.$levelKey.storyReading': updatedStoryReading,
      'readingProgress.$levelKey.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Finish Book always uses the current recording when present, or the
  // best saved page result when that page was not rerecorded this visit.
  Future<void> _finishBook(int totalPages) async {
    if (_isFinishingBook) return;
    setState(() => _isFinishingBook = true);
    late final Map<String, dynamic> result;
    try {
      result = await _calculateBookResult(totalPages);
      // Visiting a completed book without any new recording is just a view:
      // calculate from the best page results but do not count a new attempt.
      if (_currentAttemptByPage.isNotEmpty) {
        await _saveReadingProgress(result: result, totalPages: totalPages);
        debugPrint('✅ Current/mixed weighted book result saved to Firestore');
      } else {
        debugPrint('✅ Showing book score from saved best pages');
      }
      if (mounted) setState(() => _hasCompletedBook = true);
    } catch (e) {
      debugPrint('❌ Unable to finish book: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not finish book: $e')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isFinishingBook = false);
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
        // Drop on-screen LAST attempts when starting again. The best saved
        // result is still in _assessmentByPage and will appear until rerecorded.
        _latestAssessmentByPage.clear();
        _currentAttemptByPage.clear();
        _savedPages.clear();
        // Keep the best saved page results available during rereading.
        // New attempts will only replace them when the score improves.
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

      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_tintTop, _tintTop, _tintBottom],
                stops: [
                  0.0,
                  (MediaQuery.of(context).size.width *
                          848 /
                          1264 /
                          MediaQuery.of(context).size.height)
                      .clamp(0.1, 0.8)
                      .toDouble(),
                  1.0,
                ],
              ),
            ),
            child: _isLoadingSavedProgress
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ReadingPage.primaryGreen,
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('reading_books')
                        .doc(widget.bookId)
                        .collection('pages')
                        .orderBy('page_number')
                        .snapshots(),

                    builder: (context, pagesSnap) {
                      if (pagesSnap.connectionState ==
                          ConnectionState.waiting) {
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

                      final String imagePath =
                          (pageData['image_storage_path'] ?? '').toString();

                      // Display latest attempt; retain best separately for scoring.
                      final Map<String, dynamic>? assessment =
                          _latestAssessmentByPage[safeCurrentPage] ??
                          _assessmentByPage[safeCurrentPage];

                      final bool hasRecording =
                          _recordingsByPage.containsKey(safeCurrentPage) ||
                          assessment != null;

                      final bool currentPageAssessed =
                          _currentAttemptByPage.containsKey(safeCurrentPage);
                      final bool currentPageSaved = _savedPages.contains(
                        safeCurrentPage,
                      );

                      final bool isLastPage =
                          safeCurrentPage == pages.length - 1;

                      final bool allPagesReady =
                          _hasAllBookPageResults(pages.length);

                      return Stack(
                        children: [
                          Column(
                            children: [
                              // =================================================
                              // STORY CONTENT
                              // =================================================
                              Expanded(
                                // The bottom of the scrolling content fades out softly,
                                // so nothing is cut with a hard line above the buttons.
                                child: ShaderMask(
                                  blendMode: BlendMode.dstIn,
                                  shaderCallback: (rect) {
                                    final double fade = R.space(28);
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: const [
                                        Colors.white,
                                        Colors.white,
                                        Colors.transparent,
                                      ],
                                      stops: [
                                        0.0,
                                        1.0 - (fade / rect.height),
                                        1.0,
                                      ],
                                    ).createShader(rect);
                                  },
                                  child: SingleChildScrollView(
                                    key: ValueKey(
                                      'story_scroll_$safeCurrentPage',
                                    ),
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // =================================================
                                        // STORY: PICTURE AT THE TOP + TEXT
                                        // =================================================
                                        _StoryScene(
                                          key: ValueKey(
                                            'story_scene_$safeCurrentPage',
                                          ),
                                          storagePath: imagePath,
                                          text: text,
                                          useOpenDyslexic:
                                              widget.useOpenDyslexic,
                                          onColors: _onPictureColors,
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
                                                  : () =>
                                                        _toggleRecording(text),

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
                                                          ? Icons
                                                                .stop_circle_rounded
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
                                                  useOpenDyslexic:
                                                      widget.useOpenDyslexic,
                                                  fontSize: R.text(15),
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),

                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _isRecording
                                                    ? Colors.redAccent
                                                    : ReadingPage.primaryGreen,
                                                disabledBackgroundColor:
                                                    ReadingPage.primaryGreen
                                                        .withOpacity(0.55),
                                                disabledForegroundColor:
                                                    Colors.white,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        R.radius(18),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // (RECORDING SAVED widget removed)

                                        // =================================================
                                        // DETAILED PAGE RESULT
                                        // =================================================
                                        if (assessment != null &&
                                            !_isAnalyzing) ...[
                                          SizedBox(height: R.space(12)),

                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: R.pagePad,
                                            ),
                                            child: _PageReadingResultCard(
                                              assessment: assessment,
                                              fallbackExpectedText: text,
                                              useOpenDyslexic:
                                                  widget.useOpenDyslexic,
                                            ),
                                          ),
                                        ],

                                        SizedBox(height: R.space(22)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // =================================================
                              // BACK / NEXT / FINISH (no background, only buttons)
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
                                    // There is no previous story page on Page 1.
                                    if (safeCurrentPage > 0) ...[
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _isRecording ||
                                                  _isAnalyzing ||
                                                  _isFinishingBook
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _currentPage =
                                                        safeCurrentPage - 1;
                                                  });
                                                },
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                          ),
                                          label: const Text('Back'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                ReadingPage.primaryGreen,
                                            side: BorderSide(
                                              color: ReadingPage.primaryGreen
                                                  .withOpacity(0.45),
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
                                    ] else ...[
                                      // Preserve the same half-row width as on later pages.
                                      const Expanded(child: SizedBox.shrink()),
                                      SizedBox(width: R.space(12)),
                                    ],

                                    // NEXT / FINISH
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isRecording ||
                                                _isAnalyzing ||
                                                _isFinishingBook ||
                                                (isLastPage
                                                    ? !allPagesReady
                                                    : (!_hasCompletedBook &&
                                                        (!currentPageAssessed ||
                                                            !currentPageSaved)))
                                            ? null
                                            : isLastPage
                                            ? () => _finishBook(pages.length)
                                            : () {
                                                setState(() {
                                                  _currentPage =
                                                      safeCurrentPage + 1;
                                                });
                                              },

                                        icon: Icon(
                                          isLastPage
                                              ? Icons.auto_awesome_rounded
                                              : Icons.arrow_forward_rounded,
                                        ),

                                        label: Text(
                                          isLastPage ? 'Finish Book' : 'Next',
                                        ),

                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ReadingPage.primaryGreen,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: ReadingPage
                                              .primaryGreen
                                              .withOpacity(0.25),
                                          disabledForegroundColor:
                                              Colors.white70,
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
                          ),

                          // ---------------- PAGE CHIP ----------------
                          Positioned(
                            top: R.safeTop + R.space(10),
                            right: R.pagePad,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: R.space(12),
                                vertical: R.space(7),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(
                                  R.radius(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${safeCurrentPage + 1} / ${pages.length}',
                                    style: AppTypography.getStyle(
                                      useOpenDyslexic: widget.useOpenDyslexic,
                                      fontSize: R.text(12),
                                      fontWeight: FontWeight.w700,
                                      color: ReadingPage.primaryGreen,
                                    ),
                                  ),
                                  SizedBox(width: R.space(8)),
                                  SizedBox(
                                    width: R.space(36),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        R.radius(10),
                                      ),
                                      child: LinearProgressIndicator(
                                        value:
                                            (safeCurrentPage + 1) /
                                            pages.length,
                                        minHeight: R.space(5),
                                        backgroundColor: ReadingPage
                                            .primaryGreen
                                            .withOpacity(0.18),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              ReadingPage.primaryGreen,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // ---------------- FLOATING BACK BUTTON ----------------
          Positioned(
            top: R.safeTop + R.space(6),
            left: R.pagePad - R.space(4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: R.icon(24),
              color: ReadingPage.textDark,
              onPressed: _isRecording || _isAnalyzing
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),
        ],
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
    final double score = _toDouble(assessment['page_score']).clamp(0.0, 100.0);
    final int additions = _toInt(assessment['additions']);
    final String expectedText =
        (assessment['expected_text'] ?? fallbackExpectedText).toString().trim();
    final String recognizedText = (assessment['recognized_text'] ?? '')
        .toString()
        .trim();

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
          SizedBox(height: R.space(14)),
          _ColoredStoryFeedback(
            expectedText: expectedText,
            recognizedText: recognizedText,
            extraWords: additions,
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
        ],
      ),
    );
  }
}

// Display-only feedback for the most recent recording.
class _ColoredStoryFeedback extends StatelessWidget {
  final String expectedText;
  final String recognizedText;
  final int extraWords;
  final bool useOpenDyslexic;

  const _ColoredStoryFeedback({
    required this.expectedText,
    required this.recognizedText,
    required this.extraWords,
    required this.useOpenDyslexic,
  });

  static String _normalize(String word) =>
      word.toLowerCase().replaceAll(RegExp(r"[^a-z0-9']"), '');

  List<int> _wordStatuses(List<String> expected, List<String> heard) {
    final int n = expected.length;
    final int m = heard.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (int i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= m; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final int cost = _normalize(expected[i - 1]) == _normalize(heard[j - 1])
            ? 0
            : 1;
        dp[i][j] = math.min(
          dp[i - 1][j - 1] + cost,
          math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
        );
      }
    }
    // 0 correct, 1 changed, 2 missed.
    final statuses = List<int>.filled(n, 2);
    int i = n;
    int j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final bool same =
            _normalize(expected[i - 1]) == _normalize(heard[j - 1]);
        if (dp[i][j] == dp[i - 1][j - 1] + (same ? 0 : 1)) {
          statuses[i - 1] = same ? 0 : 1;
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        i--;
      } else if (j > 0) {
        j--;
      } else {
        i--;
      }
    }
    return statuses;
  }

  Widget _legendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(fontSize: R.text(10), color: ReadingPage.textDark),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final expected = expectedText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final heard = recognizedText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final statuses = _wordStatuses(expected, heard);
    const backgrounds = [
      Color(0xFFC5E2B9),
      Color(0xFFEBAEA5),
      Color(0xFFD3D3D3),
    ];
    const foregrounds = [
      Color(0xFF287442),
      Color(0xFFA62720),
      Color(0xFF515B5B),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(R.space(12)),
      decoration: BoxDecoration(
        color: ReadingPage.softCream.withOpacity(0.72),
        borderRadius: BorderRadius.circular(R.radius(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Reading',
            style: AppTypography.getStyle(
              useOpenDyslexic: useOpenDyslexic,
              fontSize: R.text(13),
              fontWeight: FontWeight.w700,
              color: ReadingPage.textDark,
            ),
          ),
          SizedBox(height: R.space(10)),
          if (expected.isEmpty)
            Text(
              'No story text available.',
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
                fontSize: R.text(12),
                color: ReadingPage.textDark,
              ),
            )
          else
            Wrap(
              spacing: R.space(7),
              runSpacing: R.space(9),
              children: [
                for (int i = 0; i < expected.length; i++)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: R.space(9),
                      vertical: R.space(7),
                    ),
                    decoration: BoxDecoration(
                      color: backgrounds[statuses[i]],
                      borderRadius: BorderRadius.circular(R.radius(10)),
                    ),
                    child: Text(
                      expected[i],
                      style: AppTypography.getStyle(
                        useOpenDyslexic: useOpenDyslexic,
                        fontSize: R.text(17),
                        fontWeight: FontWeight.w700,
                        color: foregrounds[statuses[i]],
                      ),
                    ),
                  ),
              ],
            ),
          SizedBox(height: R.space(12)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: R.icon(16),
                color: const Color(0xFF7789D8),
              ),
              SizedBox(width: R.space(6)),
              Text(
                'Extra words: $extraWords',
                style: AppTypography.getStyle(
                  useOpenDyslexic: useOpenDyslexic,
                  fontSize: R.text(12),
                  fontWeight: FontWeight.w600,
                  color: ReadingPage.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: R.space(12)),
          Wrap(
            spacing: R.space(13),
            runSpacing: R.space(6),
            children: [
              _legendItem('Correct', const Color(0xFF287442)),
              _legendItem('Wrong', const Color(0xFFA62720)),
              _legendItem('Missed', const Color(0xFF747474)),
            ],
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
    with TickerProviderStateMixin {
  // One timeline for the whole page: every part appears in turn.
  late final AnimationController _controller;

  // Gentle never-ending breathing for the sparkles and the ring glow.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulse.dispose();
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

  // Fresh green for good scores, warm amber otherwise (never harsh red).
  List<Color> get _ringColors {
    if (widget.score >= 75) {
      return const [Color(0xFF3F9E78), Color(0xFF9BDDBE)];
    }
    return const [Color(0xFFEE9A3A), Color(0xFFF8D38E)];
  }

  List<Color> get _backgroundColors {
    if (widget.score >= 75) {
      return const [Color(0xFFE3F5EB), Color(0xFFFFFDFB), Color(0xFFFFF6F1)];
    }
    return const [Color(0xFFFFF0DB), Color(0xFFFFFDFB), Color(0xFFFFF6F1)];
  }

  double _t(double begin, double end, [Curve curve = Curves.easeOutCubic]) {
    return Interval(begin, end, curve: curve).transform(_controller.value);
  }

  // Fade in and rise a little.
  Widget _reveal({
    required double begin,
    required double end,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, c) {
        final double t = _t(begin, end);

        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * R.space(24)),
            child: c,
          ),
        );
      },
    );
  }

  // Fade in and pop with a little bounce.
  Widget _pop({
    required double begin,
    required double end,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, c) {
        final double o = _t(begin, end, Curves.easeOut);
        final double sc = 0.6 + 0.4 * _t(begin, end, Curves.easeOutBack);

        return Opacity(
          opacity: o.clamp(0.0, 1.0),
          child: Transform.scale(scale: sc, child: c),
        );
      },
    );
  }

  Widget _sparkle({
    required IconData icon,
    required double size,
    required double begin,
    required double phase,
  }) {
    return _pop(
      begin: begin,
      end: begin + 0.16,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final double wave = math.sin(_pulse.value * math.pi + phase);

          return Transform.rotate(
            angle: wave * 0.12,
            child: Transform.scale(
              scale: 1 + 0.10 * wave,
              child: Icon(
                icon,
                size: size,
                color: const Color(0xFFF1B74A),
                shadows: [
                  Shadow(
                    color: const Color(0xFFF1B74A).withOpacity(0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double safeScore = widget.score.clamp(0.0, 100.0);
    final List<Color> ringColors = _ringColors;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _backgroundColors,
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

            child: Column(
              children: [
                // --------------------------------------------
                // DECORATIVE STARS
                // --------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _sparkle(
                      icon: Icons.auto_awesome_rounded,
                      size: R.icon(18),
                      begin: 0.10,
                      phase: 0.0,
                    ),

                    SizedBox(width: R.space(8)),

                    _sparkle(
                      icon: Icons.star_rounded,
                      size: R.icon(30),
                      begin: 0.00,
                      phase: 1.2,
                    ),

                    SizedBox(width: R.space(8)),

                    _sparkle(
                      icon: Icons.auto_awesome_rounded,
                      size: R.icon(18),
                      begin: 0.16,
                      phase: 2.4,
                    ),
                  ],
                ),

                SizedBox(height: R.space(12)),

                // --------------------------------------------
                // TITLE
                // --------------------------------------------
                _reveal(
                  begin: 0.06,
                  end: 0.28,
                  child: Column(
                    children: [
                      Text(
                        'Story Complete!',
                        textAlign: TextAlign.center,
                        style: AppTypography.getStyle(
                          useOpenDyslexic: widget.useOpenDyslexic,
                          fontSize: R.text(26),
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
                          color: ringColors[0].withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: R.space(22)),

                // --------------------------------------------
                // ANIMATED BOOK COVER
                // --------------------------------------------
                _pop(
                  begin: 0.14,
                  end: 0.42,
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
                          color: ringColors[0].withOpacity(0.30),
                          blurRadius: 26,
                          offset: const Offset(3, 12),
                        ),
                        BoxShadow(
                          color: ReadingPage.textDark.withOpacity(0.10),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
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
                              color: ReadingPage.primaryGreen.withOpacity(0.35),
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
                _reveal(
                  begin: 0.30,
                  end: 0.54,
                  child: Column(
                    children: [
                      Text(
                        _resultTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.getStyle(
                          useOpenDyslexic: widget.useOpenDyslexic,
                          fontSize: R.text(21),
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
                    ],
                  ),
                ),

                SizedBox(height: R.space(24)),

                // --------------------------------------------
                // ANIMATED SCORE
                // --------------------------------------------
                _pop(
                  begin: 0.34,
                  end: 0.58,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_controller, _pulse]),
                    builder: (context, _) {
                      final double value = safeScore * _t(0.38, 0.88);
                      final double glow = 0.16 + 0.07 * _pulse.value;

                      return Container(
                        width: R.icon(200),
                        height: R.icon(200),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              ringColors[0].withOpacity(glow),
                              ringColors[0].withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: R.icon(150),
                            height: R.icon(150),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: Size.infinite,
                                  painter: _ScoreRingPainter(
                                    progress: value / 100,
                                    strokeWidth: R.space(13),
                                    colors: ringColors,
                                    trackColor: ringColors[0].withOpacity(0.13),
                                  ),
                                ),

                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${value.round()}%',
                                      style: AppTypography.getStyle(
                                        useOpenDyslexic: widget.useOpenDyslexic,
                                        fontSize: R.text(34),
                                        fontWeight: FontWeight.w800,
                                        color: ringColors[0],
                                      ),
                                    ),

                                    SizedBox(height: R.space(2)),

                                    Text(
                                      'Reading Score',
                                      style: AppTypography.getStyle(
                                        useOpenDyslexic: widget.useOpenDyslexic,
                                        fontSize: R.text(10),
                                        fontWeight: FontWeight.w600,
                                        color: ReadingPage.textDark.withOpacity(
                                          0.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: R.space(22)),

                // --------------------------------------------
                // READING SUMMARY CARD
                // --------------------------------------------
                _reveal(
                  begin: 0.56,
                  end: 0.80,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(R.space(18)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(R.radius(24)),
                      border: Border.all(
                        color: ringColors[0].withOpacity(0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ringColors[0].withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 9),
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
                              child: _pop(
                                begin: 0.62,
                                end: 0.80,
                                child: _ResultStatCard(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Correct words',
                                  value: widget.correct,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: ReadingPage.primaryGreen,
                                  backgroundColor: const Color(0xFFEAF6F0),
                                ),
                              ),
                            ),

                            SizedBox(width: R.space(10)),

                            Expanded(
                              child: _pop(
                                begin: 0.67,
                                end: 0.85,
                                child: _ResultStatCard(
                                  icon: Icons.swap_horiz_rounded,
                                  label: 'Changed words',
                                  value: widget.substitutions,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: const Color(0xFFF0A24A),
                                  backgroundColor: const Color(0xFFFFF5E8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: R.space(10)),

                        Row(
                          children: [
                            Expanded(
                              child: _pop(
                                begin: 0.72,
                                end: 0.90,
                                child: _ResultStatCard(
                                  icon: Icons.remove_circle_outline_rounded,
                                  label: 'Missed words',
                                  value: widget.omissions,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: const Color(0xFFE36E6E),
                                  backgroundColor: const Color(0xFFFFEEEE),
                                ),
                              ),
                            ),

                            SizedBox(width: R.space(10)),

                            Expanded(
                              child: _pop(
                                begin: 0.77,
                                end: 0.95,
                                child: _ResultStatCard(
                                  icon: Icons.add_circle_outline_rounded,
                                  label: 'Extra words',
                                  value: widget.additions,
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  iconColor: const Color(0xFF7789D8),
                                  backgroundColor: const Color(0xFFEEF1FF),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: R.space(15)),

                        Divider(color: ReadingPage.textDark.withOpacity(0.08)),

                        SizedBox(height: R.space(8)),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: R.icon(17),
                              color: ringColors[0],
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
                ),

                SizedBox(height: R.space(24)),

                // --------------------------------------------
                // READ AGAIN
                // --------------------------------------------
                _reveal(
                  begin: 0.82,
                  end: 0.96,
                  child: SizedBox(
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
                ),

                SizedBox(height: R.space(10)),

                // --------------------------------------------
                // BACK TO LIBRARY
                // --------------------------------------------
                _reveal(
                  begin: 0.88,
                  end: 1.0,
                  child: SizedBox(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SCORE RING PAINTER
// ============================================================

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;
  final Color trackColor;

  _ScoreRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;

    canvas.drawCircle(center, radius, track);

    final double sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    if (sweep <= 0) return;

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [colors[1], colors[0], colors[1]],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor;
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
// STORY SCENE (picture on top, colors from the picture, story text)
// ============================================================

class _StoryScene extends StatefulWidget {
  final String storagePath;
  final String text;
  final bool useOpenDyslexic;
  final void Function(Color top, Color bottom) onColors;

  const _StoryScene({
    super.key,
    required this.storagePath,
    required this.text,
    required this.useOpenDyslexic,
    required this.onColors,
  });

  @override
  State<_StoryScene> createState() => _StorySceneState();
}

class _StorySceneState extends State<_StoryScene> {
  // Remember the colors of pictures we already looked at.
  static final Map<String, List<Color>> _colorCache = {};

  String? _url;
  bool _failed = false;

  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String path = widget.storagePath;
    if (path.isEmpty) return;

    final List<Color>? cached = _colorCache[path];

    if (cached != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onColors(cached[0], cached[1]);
      });
    }

    try {
      final String url = await FirebaseStorage.instance
          .ref(path)
          .getDownloadURL();

      if (!mounted) return;

      setState(() => _url = url);

      if (cached == null) _resolveColors(url, path);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _resolveColors(String url, String path) {
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        _extractColors(info.image, path);
      },
      onError: (_, _) {
        stream.removeListener(listener);
      },
    );

    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  Future<void> _extractColors(ui.Image image, String path) async {
    try {
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (data == null) return;

      final int w = image.width;
      final int h = image.height;

      Color average(int y0, int y1, int step) {
        double r = 0, g = 0, b = 0;
        int n = 0;

        for (int y = y0; y < y1; y += step) {
          for (int x = 0; x < w; x += step) {
            final int i = (y * w + x) * 4;
            r += data.getUint8(i);
            g += data.getUint8(i + 1);
            b += data.getUint8(i + 2);
            n++;
          }
        }

        if (n == 0) return ReadingPage.softCream;

        return Color.fromARGB(
          255,
          (r / n).round(),
          (g / n).round(),
          (b / n).round(),
        );
      }

      // Bottom edge of the picture -> the color the picture melts into.
      final Color edge = average((h * 0.88).floor(), h, 4);

      // Whole picture -> the softer color further down the screen.
      final Color overall = average(0, h, 12);

      final Color top = Color.lerp(edge, Colors.white, 0.66)!;
      final Color bottom = Color.lerp(overall, Colors.white, 0.86)!;

      _colorCache[path] = [top, bottom];

      if (mounted) widget.onColors(top, bottom);
    } catch (e) {
      debugPrint('Could not read picture colors: $e');
    }
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  Widget _picture() {
    if (widget.storagePath.isEmpty || _failed) {
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.black26),
      );
    }

    if (_url == null) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: ReadingPage.primaryGreen,
        ),
      );
    }

    return Image.network(
      _url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.black26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The picture keeps its real shape, so nothing is cropped.
        final double imageHeight = constraints.maxWidth * 848 / 1264;
        // Positive = text starts a little below the picture.
        final double textGap = R.space(2);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ---------------- PICTURE (melts into the background) ----------------
            SizedBox(
              width: double.infinity,
              height: imageHeight,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.52, 1.0],
                ).createShader(rect),
                child: _picture(),
              ),
            ),

            // ---------------- STORY TEXT ----------------
            Padding(
              padding: EdgeInsets.only(top: imageHeight + textGap),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) {
                  return Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - v) * R.space(18)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: R.pagePad + R.space(12),
                  ),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    // Keep the story sentence in the regular font.
                    style: AppTypography.getStyle(
                      useOpenDyslexic: false,
                      fontSize: R.text(22),
                      fontWeight: FontWeight.w500,
                      color: ReadingPage.textDark,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
          errorBuilder: (_, _, _) => const Center(
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
