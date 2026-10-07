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
import 'widgets/lexia_popup.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  void _showLockedPopup({
    required BuildContext context,
    required bool useOpenDyslexic,
  }) {
    LexiaPopup.showMessage(
      context: context,
      title: 'Locked Story',
      message: 'Keep progressing to unlock this story.',
      emoji: '🔒',
      buttonColor: primaryGreen,
      buttonText: 'Got it!',
      useOpenDyslexic: useOpenDyslexic,
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(105);

    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid.isEmpty
          ? null
          : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};

        final bool useOpenDyslexic = userData['useOpenDyslexicFont'] == true;

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
                      '✨ Unlock stories as you progress',
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

                        final Map<String, Map<String, dynamic>> bookDataById = {
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
                            'locked': false,
                          },
                          {
                            'id': 'book_2',
                            'name': book2['title'] ?? 'Book 2',
                            'coverPath':
                                book2['cover_image_storage_path'] ?? '',
                            'locked': false,
                          },
                          {
                            'id': 'book_3',
                            'name': book3['title'] ?? 'Book 3',
                            'coverPath':
                                book3['cover_image_storage_path'] ?? '',
                            'locked': false,
                          },
                          {
                            'id': 'book_4',
                            'name': book4['title'] ?? 'Book 4',
                            'coverPath':
                                book4['cover_image_storage_path'] ?? '',
                            'locked': false,
                          },
                          {
                            'id': 'book_5',
                            'name': book5['title'] ?? 'Book 5',
                            'coverPath':
                                book5['cover_image_storage_path'] ?? '',
                            'locked': false,
                          },
                          {
                            'id': 'book_6',
                            'name': book6['title'] ?? 'Book 6',
                            'coverPath':
                                book6['cover_image_storage_path'] ?? '',
                            'locked': false,
                          },
                        ];

                        return Column(
                          children: [
                            for (int i = 0; i < 3; i++)
                              _WoodenShelfRow(
                                items: books.sublist(i * 2, i * 2 + 2),
                                useOpenDyslexic: useOpenDyslexic,
                                onStoryTap: (book) {
                                  final bool isLocked = book['locked'] == true;

                                  if (isLocked) {
                                    _showLockedPopup(
                                      context: context,
                                      useOpenDyslexic: useOpenDyslexic,
                                    );

                                    return;
                                  }

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BookReaderPage(
                                        bookId: book['id'] as String,
                                        title: book['name'] as String,
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
                  if (!isLocked &&
                      (data['coverPath'] ?? '').toString().isNotEmpty)
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
                      color: Colors.white.withOpacity(0.50),
                      child: Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: ReadingPage.textDark.withOpacity(0.45),
                          size: R.icon(24),
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
  final bool useOpenDyslexic;

  const BookReaderPage({
    super.key,
    required this.bookId,
    required this.title,
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

  // ==========================================================
  // START RECORDING
  // ==========================================================

  Future<void> _startRecording() async {
    try {
      final bool hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record.'),
          ),
        );

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start recording: $e')));
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

      // Android Emulator:
      // 10.0.2.2 points to the Mac running the Flask server.
      final Uri uri = Uri.parse(
        'https://lexia-asr-100861482313.me-central1.run.app/reading-assessment',
      );

      final request = http.MultipartRequest('POST', uri);

      // Story text from Firestore.
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reading score: ${result['page_score']}%')),
      );
    } catch (e) {
      debugPrint('❌ Assessment error: $e');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not analyze recording: $e')),
      );
    }
  }

  // ==========================================================
  // STOP RECORDING
  // ==========================================================

  Future<void> _stopRecording(String expectedText) async {
    try {
      // Save the page index before awaiting.
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Page ${pageIndex + 1} recording saved ✓')),
        );

        // Automatically send the recording
        // to Kid-Whisper after stopping.
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not stop recording: $e')));
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

          // Prevent leaving while recording
          // or while ASR is processing.
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

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reading_books')
            .doc(widget.bookId)
            .collection('pages')
            .orderBy('page_number')
            .snapshots(),

        builder: (context, pagesSnap) {
          if (pagesSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ReadingPage.primaryGreen),
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

          final int safeCurrentPage = _currentPage.clamp(0, pages.length - 1);

          final pageData = pages[safeCurrentPage].data();

          // This is the expected text
          // that will be sent to the backend.
          final String text = (pageData['text'] ?? '').toString();

          final String imagePath = (pageData['image_storage_path'] ?? '')
              .toString();

          final bool hasRecording = _recordingsByPage.containsKey(
            safeCurrentPage,
          );

          final Map<String, dynamic>? assessment =
              _assessmentByPage[safeCurrentPage];

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
                      margin: EdgeInsets.symmetric(horizontal: R.space(3)),
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
              // PAGE CONTENT
              // =================================================
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---------------------------
                      // STORY IMAGE
                      // ---------------------------
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

                      // ---------------------------
                      // STORY TEXT
                      // ---------------------------
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
                        padding: EdgeInsets.symmetric(horizontal: R.pagePad),
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
                                    child: const CircularProgressIndicator(
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

                              disabledBackgroundColor: ReadingPage.primaryGreen
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
                      // ANALYZING INDICATOR
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
                      if (hasRecording && !_isRecording && !_isAnalyzing) ...[
                        SizedBox(height: R.space(10)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: ReadingPage.primaryGreen,
                              size: R.icon(17),
                            ),

                            SizedBox(width: R.space(5)),

                            Text(
                              'Recording saved',
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
                      // TEMPORARY RESULT FOR TESTING
                      // =================================================
                      if (assessment != null && !_isAnalyzing) ...[
                        SizedBox(height: R.space(10)),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: R.pagePad),
                          child: Column(
                            children: [
                              Text(
                                'Score: ${assessment['page_score']}%',
                                textAlign: TextAlign.center,
                                style: AppTypography.getStyle(
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  fontSize: R.text(14),
                                  fontWeight: FontWeight.w600,
                                  color: ReadingPage.primaryGreen,
                                ),
                              ),

                              SizedBox(height: R.space(4)),

                              Text(
                                'Heard: ${assessment['recognized_text'] ?? ''}',
                                textAlign: TextAlign.center,
                                style: AppTypography.getStyle(
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  fontSize: R.text(11),
                                  color: ReadingPage.textDark.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: R.space(22)),
                    ],
                  ),
                ),
              ),

              // =================================================
              // BACK / NEXT
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
                    // ---------------------------
                    // BACK
                    // ---------------------------
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            safeCurrentPage == 0 || _isRecording || _isAnalyzing
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
                            color: ReadingPage.primaryGreen.withOpacity(0.45),
                          ),

                          padding: EdgeInsets.symmetric(vertical: R.space(13)),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(R.radius(18)),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: R.space(12)),

                    // ---------------------------
                    // NEXT
                    // ---------------------------
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            safeCurrentPage >= pages.length - 1 ||
                                _isRecording ||
                                _isAnalyzing
                            ? null
                            : () {
                                setState(() {
                                  _currentPage = safeCurrentPage + 1;
                                });
                              },

                        icon: const Icon(Icons.arrow_forward_rounded),

                        label: const Text('Next'),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReadingPage.primaryGreen,

                          foregroundColor: Colors.white,

                          disabledBackgroundColor: ReadingPage.primaryGreen
                              .withOpacity(0.25),

                          disabledForegroundColor: Colors.white70,

                          elevation: 0,

                          padding: EdgeInsets.symmetric(vertical: R.space(13)),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(R.radius(18)),
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
