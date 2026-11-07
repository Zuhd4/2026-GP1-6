import 'dart:typed_data';
import 'auth_identity.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_typography.dart';
import 'responsive_helper.dart';

class MyBookPage extends StatelessWidget {
  const MyBookPage({super.key, required this.childId});

  final String childId;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(105);

    final String uid = AuthIdentity.parentUid;

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: ivoryWhite,
        body: Center(child: Text('User not found')),
      );
    }

    if (childId.isEmpty) {
      return Scaffold(
        backgroundColor: ivoryWhite,
        body: Center(
          child: Text(
            'No child selected.',
            style: AppTypography.getStyle(
              useOpenDyslexic: false,
              fontSize: R.text(16),
              fontWeight: FontWeight.w500,
              color: textDark.withOpacity(0.8),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .snapshots(),
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

            /// مهم: بدون R.pageWrap هنا
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
                    'My Book',
                    style: AppTypography.getStyle(
                      useOpenDyslexic: useOpenDyslexic,
                      fontSize: R.text(21),
                      fontWeight: FontWeight.w500,
                      color: textDark.withOpacity(0.9),
                    ),
                  ),

                  SizedBox(height: R.space(28)),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('children')
                        .doc(childId)
                        .collection('sharedDocuments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading documents.',
                            style: AppTypography.getStyle(
                              useOpenDyslexic: useOpenDyslexic,
                              fontSize: R.text(14),
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No documents shared yet.',
                            style: AppTypography.getStyle(
                              useOpenDyslexic: useOpenDyslexic,
                              fontSize: R.text(14),
                              color: textDark.withOpacity(0.6),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: docs.map((docSnap) {
                          final data = docSnap.data();
                          final String? coverUrl =
                              (data['coverUrl'] as String?) ??
                              (data['thumbnailUrl'] as String?) ??
                              (data['imageUrl'] as String?);
                          final String? coverStoragePath =
                              (data['imageStoragePath'] as String?) ??
                              (data['coverStoragePath'] as String?) ??
                              (data['thumbnailStoragePath'] as String?) ??
                              (data['parentStoragePath'] as String?) ??
                              (data['storagePath'] as String?);
                          final String name =
                              (data['name'] as String?)?.trim().isNotEmpty ==
                                  true
                              ? data['name'] as String
                              : 'Untitled Document';
                          final String extractedText =
                              (data['extractedText'] as String?) ?? '';
                          final rawDifficulties = data['difficultyByWord'];
                          final difficultyByWord = <String, String>{};
                          if (rawDifficulties is Map) {
                            rawDifficulties.forEach((key, value) {
                              if (key is String && value is String) {
                                difficultyByWord[key.toLowerCase().replaceAll(
                                  '’',
                                  "'",
                                )] = value
                                    .toLowerCase();
                              }
                            });
                          }
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _DocumentReaderPage(
                                    title: name,
                                    extractedText: extractedText,
                                    useInterfaceOpenDyslexic: useOpenDyslexic,
                                    useOpenDyslexic:
                                        data['useOpenDyslexicFont'] == true,
                                    difficultyByWord: difficultyByWord,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: R.space(16)),
                              padding: EdgeInsets.all(R.space(14)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  R.radius(22),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.025),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _DocumentCover(
                                    url: coverUrl,
                                    storagePath: coverStoragePath,
                                  ),
                                  SizedBox(width: R.space(12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTypography.getStyle(
                                            useOpenDyslexic: useOpenDyslexic,
                                            fontSize: R.text(14),
                                            fontWeight: FontWeight.w600,
                                            color: textDark.withOpacity(0.9),
                                          ),
                                        ),
                                        SizedBox(height: R.space(4)),
                                        Text(
                                          'Sent by parent',
                                          style: AppTypography.getStyle(
                                            useOpenDyslexic: useOpenDyslexic,
                                            fontSize: R.text(11),
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: R.icon(22),
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DocumentReaderPage extends StatefulWidget {
  const _DocumentReaderPage({
    required this.title,
    required this.extractedText,
    required this.useOpenDyslexic,
    required this.useInterfaceOpenDyslexic,
    required this.difficultyByWord,
  });

  final String title;
  final String extractedText;
  final bool useOpenDyslexic;
  final bool useInterfaceOpenDyslexic;
  final Map<String, String> difficultyByWord;

  @override
  State<_DocumentReaderPage> createState() => _DocumentReaderPageState();
}

class _DocumentReaderPageState extends State<_DocumentReaderPage> {
  static final RegExp _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?");

  static const Color mediumHighlight = Color(0xFFFFF176);
  static const Color hardHighlight = Color(0xFFFFB74D);

  final FlutterTts _tts = FlutterTts();

  double _readingFontSize = 15;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.43);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS setup error: $e');
    }
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();

      if (mounted) {
        setState(() => _isSpeaking = false);
      }
      return;
    }

    final text = widget.extractedText.trim();
    if (text.isEmpty) return;

    setState(() => _isSpeaking = true);

    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speaking error: $e');

      if (!mounted) return;

      setState(() => _isSpeaking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read text aloud.')),
      );
    }
  }

  void _changeFontSize(double change) {
    setState(() {
      _readingFontSize = (_readingFontSize + change)
          .clamp(12.0, 23.0)
          .toDouble();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ============================================================
  // HIGHLIGHTED DOCUMENT TEXT
  // ============================================================

  List<InlineSpan> _highlightedSpans() {
    final text = widget.extractedText;

    if (text.trim().isEmpty) {
      return [const TextSpan(text: 'No text was detected in this document.')];
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _wordPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      final originalWord = match.group(0)!;

      final key = originalWord.toLowerCase().replaceAll('’', "'");

      final difficulty = widget.difficultyByWord[key];

      final Color? highlight = difficulty == 'medium'
          ? mediumHighlight
          : difficulty == 'hard'
          ? hardHighlight
          : null;

      if (highlight == null) {
        spans.add(TextSpan(text: originalWord));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: R.space(2),
                vertical: R.space(4),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: R.space(5),
                vertical: R.space(3),
              ),
              decoration: BoxDecoration(
                color: highlight,
                borderRadius: BorderRadius.circular(R.radius(9)),
              ),
              child: Text(
                originalWord,
                textDirection: TextDirection.ltr,
                style: AppTypography.getStyle(
                  useOpenDyslexic: widget.useOpenDyslexic,
                  fontSize: R.text(_readingFontSize),
                  fontWeight: FontWeight.w600,
                  color: MyBookPage.textDark,
                  height: 1.2,
                ),
              ),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  // ============================================================
  // MEDIUM / HARD LEGEND
  // ============================================================

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        SizedBox(width: R.space(6)),
        Text(
          label,
          style: AppTypography.getStyle(
            useOpenDyslexic: widget.useInterfaceOpenDyslexic,
            fontSize: R.text(12),
            color: MyBookPage.textDark,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // READING CONTROLS
  // ============================================================

  Widget _buildReadingControls() {
    return Wrap(
      spacing: R.space(10),
      runSpacing: R.space(8),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem('Medium', mediumHighlight),
            SizedBox(width: R.space(18)),
            _legendItem('Hard', hardHighlight),
          ],
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Decrease text size',
              onPressed: _readingFontSize <= 12
                  ? null
                  : () => _changeFontSize(-1),
              icon: const Icon(Icons.text_decrease_rounded),
              color: MyBookPage.primaryPurple,
            ),

            IconButton(
              tooltip: 'Increase text size',
              onPressed: _readingFontSize >= 23
                  ? null
                  : () => _changeFontSize(1),
              icon: const Icon(Icons.text_increase_rounded),
              color: MyBookPage.primaryPurple,
            ),

            IconButton(
              tooltip: _isSpeaking ? 'Stop reading' : 'Read text aloud',
              onPressed: _toggleSpeech,
              icon: Icon(
                _isSpeaking
                    ? Icons.stop_circle_rounded
                    : Icons.volume_up_rounded,
              ),
              color: MyBookPage.primaryPurple,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PAGE UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyBookPage.ivoryWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: MyBookPage.textDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 12,
        title: Text(
          widget.title,
          style: AppTypography.getStyle(
            useOpenDyslexic: widget.useInterfaceOpenDyslexic,
            fontSize: R.text(18),
            fontWeight: FontWeight.w500,
            color: MyBookPage.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: MyBookPage.textDark),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyBookPage.ivoryWhite,
              MyBookPage.paleBlush,
              MyBookPage.softCream,
              Colors.white,
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          R.pagePad,
          R.space(20),
          R.pagePad,
          R.pagePad,
        ),

        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medium / Hard + Font controls + TTS
              _buildReadingControls(),

              SizedBox(height: R.space(14)),

              // Document text
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(R.space(18)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(R.radius(22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Text.rich(
                  TextSpan(
                    style: AppTypography.getStyle(
                      useOpenDyslexic: widget.useOpenDyslexic,
                      fontSize: R.text(_readingFontSize),
                      height: 2.0,
                      color: MyBookPage.textDark,
                    ).copyWith(wordSpacing: 0),
                    children: _highlightedSpans(),
                  ),
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCover extends StatefulWidget {
  const _DocumentCover({this.url, this.storagePath});

  final String? url;
  final String? storagePath;

  @override
  State<_DocumentCover> createState() => _DocumentCoverState();
}

class _DocumentCoverState extends State<_DocumentCover> {
  Future<_CoverResult>? _coverFuture;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(covariant _DocumentCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.url != widget.url) {
      _loadCover();
    }
  }

  void _loadCover() {
    _coverFuture = _resolveCover();
  }

  Future<_CoverResult> _resolveCover() async {
    final path = widget.storagePath?.trim();
    final savedUrl = widget.url?.trim();
    if (path != null && path.isNotEmpty) {
      try {
        // Storage bytes use the active Firebase Authentication session.
        final bytes = await FirebaseStorage.instance
            .ref(path)
            .getData(20 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) {
          return _CoverResult(bytes: bytes);
        }
        debugPrint('MyBook cover: empty Storage object at $path');
      } on FirebaseException catch (error) {
        debugPrint(
          'MyBook cover getData FAILED at $path: '
          'code=${error.code}, message=${error.message}, '
          'signedIn=${FirebaseAuth.instance.currentUser != null}',
        );
      } catch (error) {
        debugPrint('MyBook cover getData FAILED at $path: $error');
      }

      // Some Storage environments support URL retrieval even when the direct
      // byte download fails. Keep the diagnostic messages for both attempts.
      try {
        final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
        return _CoverResult(url: url);
      } on FirebaseException catch (error) {
        debugPrint(
          'MyBook cover getDownloadURL FAILED at $path: '
          'code=${error.code}, message=${error.message}',
        );
      } catch (error) {
        debugPrint('MyBook cover getDownloadURL FAILED at $path: $error');
      }
    } else {
      debugPrint('MyBook cover: shared document has NO imageStoragePath');
    }

    if (savedUrl != null && savedUrl.isNotEmpty) {
      return _CoverResult(url: savedUrl);
    }
    return const _CoverResult();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFE8E4F8),
      alignment: Alignment.center,
      child: Icon(
        Icons.description_rounded,
        size: R.icon(30),
        color: MyBookPage.primaryPurple.withOpacity(0.75),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(R.radius(12)),
      child: SizedBox(
        width: R.icon(58),
        height: R.icon(58),
        child: FutureBuilder<_CoverResult>(
          future: _coverFuture,
          builder: (context, snapshot) {
            final result = snapshot.data;
            if (result?.bytes != null) {
              return Image.memory(
                result!.bytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('MyBook cover Image.memory FAILED: $error');
                  return fallback;
                },
              );
            }
            if (result?.url != null) {
              return Image.network(
                result!.url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('MyBook cover Image.network FAILED: $error');
                  return fallback;
                },
              );
            }
            if (snapshot.hasError) {
              debugPrint(
                'MyBook cover unexpected loading ERROR: '
                '${snapshot.error}',
              );
            }
            return fallback;
          },
        ),
      ),
    );
  }
}

class _CoverResult {
  const _CoverResult({this.bytes, this.url});
  final Uint8List? bytes;
  final String? url;
}
