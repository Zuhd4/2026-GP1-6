import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'responsive_helper.dart';
import 'scan_result_page.dart';
import 'widgets/lexia_popup.dart';

/// Simple model representing a scanned/uploaded document in this session.
/// `extractedText` holds the raw OCR output. Difficulty scoring +
/// highlighting will attach to this in a later step.
class _ScannedDocument {
  final File file;
  final String name;
  final DateTime scannedAt;
  String? extractedText;

  _ScannedDocument({
    required this.file,
    required this.name,
    required this.scannedAt,
    this.extractedText,
  });
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: 0.5,
  );
  final List<_ScannedDocument> _documents = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    _languageIdentifier.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final file = File(picked.path);
      final doc = _ScannedDocument(
        file: file,
        name: 'Scan ${_documents.length + 1}',
        scannedAt: DateTime.now(),
      );

      // Run on-device OCR
      final inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognized = await _textRecognizer.processImage(
        inputImage,
      );

      // Keep only English lines — drop lines identified as another language,
      // so a page mixing English with other text still yields clean English.
      final buffer = StringBuffer();
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final lineText = line.text.trim();
          if (lineText.isEmpty) continue;

          final lang = await _languageIdentifier.identifyLanguage(lineText);
          if (lang == 'en') {
            buffer.writeln(lineText);
          }
        }
      }
      doc.extractedText = buffer.toString().trim();

      final hasText =
          doc.extractedText != null && doc.extractedText!.isNotEmpty;

      setState(() => _isProcessing = false);

      if (!hasText) {
        // No readable English text — don't keep the image, it's not usable.
        if (mounted) {
          LexiaPopup.showMessage(
            context: context,
            title: 'No text detected',
            message:
                'We couldn\'t find any readable English text in that image. Try again with a clearer shot of the page.',
            emoji: '🔍',
            buttonColor: Colors.redAccent.withOpacity(0.8),
            buttonText: 'Try again',
          );
        }
        return;
      }

      setState(() => _documents.insert(0, doc));

      if (mounted) {
        _openResult(doc);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Something went wrong',
          message: 'We couldn\'t read that image. Please try again.',
          emoji: '⚠️',
          buttonColor: Colors.redAccent.withOpacity(0.8),
          buttonText: 'Okay',
        );
      }
    }
  }

  void _openResult(_ScannedDocument doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultPage(
          documentName: doc.name,
          extractedText: doc.extractedText ?? '',
        ),
      ),
    );
  }

  Future<void> _shareDocument(_ScannedDocument doc) async {
    try {
      await Share.shareXFiles([
        XFile(doc.file.path),
      ], text: 'Shared from Lexia — ${doc.name}');
    } catch (_) {
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Couldn\'t share',
          message: 'Please try again in a moment.',
          emoji: '⚠️',
          buttonColor: Colors.redAccent.withOpacity(0.8),
          buttonText: 'Okay',
        );
      }
    }
  }

  Future<void> _deleteDocument(_ScannedDocument doc) async {
    final confirmed = await LexiaPopup.showConfirm(
      context: context,
      title: 'Remove document?',
      message: 'This will remove "${doc.name}" from your list.',
      confirmText: 'Remove',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.redAccent,
    );

    if (confirmed) {
      setState(() => _documents.remove(doc));
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final double horizontalPad = R.pagePad;
    final double topMargin = R.safeTop + R.space(95);
    final double bottomMargin = R.safeBottom + R.space(105);

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
                'Books',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(21),
                  fontWeight: FontWeight.w500,
                  color: textDark.withOpacity(0.9),
                ),
              ),

              SizedBox(height: R.space(2)),

              Text(
                'Scan or upload any text image',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(12),
                  color: Colors.black45,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: R.space(28)),

              Container(
                width: double.infinity,
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
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.space(14),
                        vertical: R.space(24),
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBF8FF), Color(0xFFF5FAFF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(R.radius(22)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: R.icon(62),
                            height: R.icon(62),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isProcessing
                                ? Padding(
                                    padding: EdgeInsets.all(R.space(18)),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: primaryPurple,
                                    ),
                                  )
                                : Icon(
                                    Icons.document_scanner_rounded,
                                    color: primaryPurple,
                                    size: R.icon(30),
                                  ),
                          ),
                          SizedBox(width: R.space(14)),
                          Expanded(
                            child: Text(
                              _isProcessing
                                  ? 'Reading your\npage…'
                                  : 'Scan or upload\nan image',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(18),
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(R.space(14)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _btn(
                              context,
                              'Scan',
                              Icons.camera_alt_rounded,
                              () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          SizedBox(width: R.space(12)),
                          Expanded(
                            child: _btn(
                              context,
                              'Upload',
                              Icons.file_upload_outlined,
                              () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: R.space(32)),

              Text(
                'Documents',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(21),
                  fontWeight: FontWeight.w500,
                  color: textDark.withOpacity(0.9),
                ),
              ),

              SizedBox(height: R.space(2)),

              Text(
                'Send a scanned page to your child or somewhere else',
                style: GoogleFonts.montserrat(
                  fontSize: R.text(12),
                  color: Colors.black45,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: R.space(16)),

              _documents.isEmpty
                  ? _emptyDocumentsState()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _documents.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: R.space(10)),
                      itemBuilder: (context, index) =>
                          _documentTile(_documents[index]),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyDocumentsState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: R.space(28)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            color: Colors.black26,
            size: R.icon(32),
          ),
          SizedBox(height: R.space(8)),
          Text(
            'No documents yet',
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

  Widget _documentTile(_ScannedDocument doc) {
    return Container(
      padding: EdgeInsets.all(R.space(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(R.radius(12)),
              onTap: () => _openResult(doc),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(R.radius(12)),
                    child: Image.file(
                      doc.file,
                      width: R.icon(52),
                      height: R.icon(52),
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: R.space(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(14),
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: R.space(2)),
                        Text(
                          _formatDate(doc.scannedAt),
                          style: GoogleFonts.montserrat(
                            fontSize: R.text(11),
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _shareDocument(doc),
            icon: Icon(
              Icons.ios_share_rounded,
              color: primaryPurple,
              size: R.icon(20),
            ),
          ),
          IconButton(
            onPressed: () => _deleteDocument(doc),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.black26,
              size: R.icon(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: R.buttonH(54),
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : onPressed,
        icon: Icon(icon, size: R.icon(20)),
        label: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: R.text(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(16)),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),
      ),
    );
  }
}
