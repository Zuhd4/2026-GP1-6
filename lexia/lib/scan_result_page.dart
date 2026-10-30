import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'responsive_helper.dart';
import 'app_typography.dart';

/// Displays OCR text and highlights Medium/Hard words using the Python analyzer.
class ScanResultPage extends StatefulWidget {
  final String documentName;
  final String extractedText;
  final bool useOpenDyslexic;
  final ValueChanged<Map<String, String>>? onDifficultiesUpdated;

  const ScanResultPage({
    super.key,
    required this.documentName,
    required this.extractedText,
    this.useOpenDyslexic = false,
    this.onDifficultiesUpdated,
  });

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color mediumHighlight = Color(0xFFFFF176);
  static const Color hardHighlight = Color(0xFFFFB74D);
  static final Uri _analyzerUrl = Uri.parse(
    'https://lexia-word-analyzer-100861482313.me-central1.run.app/analyze',
  );
  static final RegExp _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?");

  final Map<String, String> _difficultyByWord = {};
  bool _isAnalyzing = false;
  int _analyzedCount = 0;
  int _totalUniqueWords = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _analyzeExtractedText();
  }

  @override
  void didUpdateWidget(covariant ScanResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extractedText != widget.extractedText) {
      _difficultyByWord.clear();
      _analyzeExtractedText();
    }
  }

  Future<void> _analyzeExtractedText() async {
    final words = _wordPattern
        .allMatches(widget.extractedText)
        .map((match) => match.group(0)!.toLowerCase().replaceAll('’', "'"))
        .toSet()
        .toList();

    // Keep a local copy so older requests cannot overwrite a newer scan.
    final requestedText = widget.extractedText;
    setState(() {
      _isAnalyzing = words.isNotEmpty;
      _analyzedCount = 0;
      _totalUniqueWords = words.length;
      _failedCount = 0;
    });

    // Analyze each distinct word only once. Small batches limit load on Cloud Run.
    for (var start = 0; start < words.length; start += 3) {
      final batch = words.skip(start).take(3).toList();
      final results = await Future.wait(batch.map(_analyzeWord));
      if (!mounted || widget.extractedText != requestedText) return;
      setState(() {
        for (var i = 0; i < batch.length; i++) {
          final difficulty = results[i];
          if (difficulty != null) {
            _difficultyByWord[batch[i]] = difficulty;
          } else {
            _failedCount++;
          }
        }
        _analyzedCount += batch.length;
      });
      widget.onDifficultiesUpdated?.call(
        Map<String, String>.from(_difficultyByWord),
      );
    }
    if (mounted && widget.extractedText == requestedText) {
      setState(() => _isAnalyzing = false);
      widget.onDifficultiesUpdated?.call(
        Map<String, String>.from(_difficultyByWord),
      );
    }
  }

  Future<String?> _analyzeWord(String word) async {
    try {
      final response = await http
          .post(
            _analyzerUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'word': word}),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) return null;
      final result = jsonDecode(response.body);
      if (result is! Map<String, dynamic>) return null;
      final difficulty = result['difficulty']?.toString().toLowerCase();
      if (difficulty == 'easy' ||
          difficulty == 'medium' ||
          difficulty == 'hard') {
        return difficulty;
      }
    } catch (_) {
      // Keep OCR text visible even if a request fails.
    }
    return null;
  }

  List<InlineSpan> _highlightedSpans() {
    final text = widget.extractedText;
    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in _wordPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final originalWord = match.group(0)!;
      final key = originalWord.toLowerCase().replaceAll('’', "'");
      final difficulty = _difficultyByWord[key];
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
                vertical: R.space(3),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: R.space(9),
                vertical: R.space(6),
              ),
              decoration: BoxDecoration(
                color: highlight,
                borderRadius: BorderRadius.circular(R.radius(11)),
              ),
              child: Text(
                originalWord,
                style: AppTypography.getStyle(
                  useOpenDyslexic: widget.useOpenDyslexic,
                  fontSize: R.text(15),
                  fontWeight: FontWeight.w600,
                  color: textDark,
                  height: 1.25,
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

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        leading: _isAnalyzing ? const SizedBox.shrink() : null,
        title: Text(
          widget.documentName,
          style: GoogleFonts.montserrat(
            fontSize: R.text(16),
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  R.pagePad,
                  R.space(16),
                  R.pagePad,
                  R.space(40),
                ),
                child: widget.extractedText.trim().isEmpty
                    ? _emptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isAnalyzing && _failedCount > 0) ...[
                            TextButton.icon(
                              onPressed: _analyzeExtractedText,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                '$_failedCount words could not be analyzed. Retry',
                              ),
                            ),
                            SizedBox(height: R.space(10)),
                          ],
                          Row(
                            children: [
                              _legendItem('Medium', mediumHighlight),
                              SizedBox(width: R.space(16)),
                              _legendItem('Hard', hardHighlight),
                            ],
                          ),
                          SizedBox(height: R.space(12)),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(R.space(18)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(R.radius(22)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.025),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: AppTypography.getStyle(
                                  useOpenDyslexic: widget.useOpenDyslexic,
                                  fontSize: R.text(15),
                                  height: 1.6,
                                  color: textDark,
                                ),
                                children: _highlightedSpans(),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ModalBarrier(
                      dismissible: false,
                      color: Colors.black45,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: R.space(25)),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: R.maxContentWidth < 420
                              ? R.maxContentWidth
                              : 420,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: R.space(24),
                          vertical: R.space(28),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(R.radius(24)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: primaryPurple,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: R.space(20)),
                            Text(
                              'Analyzing text',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(20),
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: R.space(8)),
                            Text(
                              'Lexia is checking word difficulty...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(12),
                                color: Colors.black45,
                              ),
                            ),
                            SizedBox(height: R.space(16)),
                            Text(
                              '$_analyzedCount / $_totalUniqueWords words',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(12),
                                color: primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: R.space(13),
          height: R.space(13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(R.radius(3)),
          ),
        ),
        SizedBox(width: R.space(6)),
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: R.text(12), color: textDark),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: R.space(40)),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.text_snippet_outlined,
            color: Colors.black26,
            size: R.icon(36),
          ),
          SizedBox(height: R.space(10)),
          Text(
            'No text was detected in this image',
            style: GoogleFonts.montserrat(
              fontSize: R.text(13),
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
