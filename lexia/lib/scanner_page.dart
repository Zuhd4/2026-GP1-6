import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  bool _isSendingToChild = false;
  final double _sendProgress = 0;
  String _sendingChildName = '';

  Future<void> _showSendProgressDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) {
          // Rebuild this dialog when the upload stream reports progress.
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: const Color(0xFFFFFDFB),
              title: const Row(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: primaryPurple),
                  SizedBox(width: 10),
                  Expanded(child: Text('Sending document')),
                ],
              ),
              content: StreamBuilder<double>(
                stream: _uploadProgressStream?.stream,
                initialData: 0,
                builder: (context, snapshot) {
                  final progress = (snapshot.data ?? 0).clamp(0.0, 1.0);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sending to $_sendingChildName',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFEAE5F7),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(progress * 100).round()}%',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  StreamController<double>? _uploadProgressStream;

  Future<void> _sendDocumentToChild(_ScannedDocument doc) async {
    if (_isSendingToChild) return;
    final parentId = FirebaseAuth.instance.currentUser?.uid;
    if (parentId == null) {
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Sign in required',
          message: 'Please sign in as a parent first.',
          emoji: '🔒',
          buttonText: 'Okay',
        );
      }
      return;
    }

    try {
      final children = await FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .get();
      if (!mounted) return;
      if (children.docs.isEmpty) {
        LexiaPopup.showMessage(
          context: context,
          title: 'No child profiles',
          message: 'Add a child profile first to send a document.',
          emoji: '🧒',
          buttonText: 'Okay',
        );
        return;
      }

      final selectedChildId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: ivoryWhite,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE8FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    size: 32,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Send to child',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose who will receive “${doc.name}”',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: children.docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (_, index) {
                      final child = children.docs[index];
                      final childName = (child.data()['name'] ?? 'Child')
                          .toString();
                      return Material(
                        color: const Color(0xFFF6F2FC),
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => Navigator.pop(dialogContext, child.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFE6DDF7),
                                  child: Icon(
                                    Icons.face_rounded,
                                    color: primaryPurple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    childName,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: primaryPurple,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(color: textDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || selectedChildId == null) return;
      final child = children.docs.firstWhere(
        (entry) => entry.id == selectedChildId,
      );
      _sendingChildName = (child.data()['name'] ?? 'Child').toString();
      _uploadProgressStream = StreamController<double>.broadcast();
      setState(() => _isSendingToChild = true);
      // Show a modal progress indicator rather than a bottom snackbar.
      final progressDialog = _showSendProgressDialog();

      try {
        final destination = FirebaseFirestore.instance
            .collection('users')
            .doc(parentId)
            .collection('children')
            .doc(selectedChildId)
            .collection('sharedDocuments')
            .doc();
        final path =
            'users/$parentId/children/$selectedChildId/sharedDocuments/${destination.id}.jpg';
        final storageRef = FirebaseStorage.instance.ref(path);
        final upload = storageRef.putFile(doc.file);
        final subscription = upload.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0 &&
              !(_uploadProgressStream?.isClosed ?? true)) {
            _uploadProgressStream?.add(
              snapshot.bytesTransferred / snapshot.totalBytes,
            );
          }
        });
        try {
          await upload;
        } finally {
          await subscription.cancel();
        }
        _uploadProgressStream?.add(1);
        try {
          await destination.set({
            'name': doc.name,
            'extractedText': doc.extractedText ?? '',
            'imageStoragePath': path,
            'createdAt': FieldValue.serverTimestamp(),
            'sentBy': parentId,
          });
        } catch (_) {
          try {
            await storageRef.delete();
          } catch (_) {}
          rethrow;
        }
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        await progressDialog;
        if (!mounted) return;
        LexiaPopup.showMessage(
          context: context,
          title: 'Sent successfully!',
          message: '“${doc.name}” was sent to $_sendingChildName.',
          emoji: '💌',
          buttonText: 'Done',
          buttonColor: primaryGreen,
        );
      } catch (error, stackTrace) {
        debugPrint('SEND DOCUMENT ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          await progressDialog;
          if (mounted) {
            final String explanation;
            if (error is FirebaseException && error.code == 'permission-denied') {
              explanation = 'Firebase permissions do not allow saving this document. Please check Firestore rules.';
            } else if (error is FirebaseException &&
                (error.code == 'unauthorized' || error.code == 'unauthenticated')) {
              explanation = 'Firebase Storage did not allow this upload. Please check Storage rules.';
            } else {
              explanation = 'The document could not be sent. Please try again.';
            }
            LexiaPopup.showMessage(
              context: context,
              title: 'Could not send',
              message: explanation,
              emoji: '⚠️',
              buttonText: 'Okay',
            );
          }
        }
      } finally {
        await _uploadProgressStream?.close();
        _uploadProgressStream = null;
        if (mounted) setState(() => _isSendingToChild = false);
      }
    } catch (error, stackTrace) {
      debugPrint('LOAD CHILDREN / SEND DOCUMENT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Could not load children',
          message: 'Please check your connection and try again.',
          emoji: '⚠️',
          buttonText: 'Okay',
        );
      }
    }
  }

  Future<String?> _askDocumentName(String suggestedName) async {
    final controller = TextEditingController(text: suggestedName);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Name your document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Document name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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

      if (!mounted) return;
      final name = await _askDocumentName(doc.name);
      if (!mounted || name == null) return;
      final namedDoc = _ScannedDocument(
        file: doc.file,
        name: name,
        scannedAt: doc.scannedAt,
        extractedText: doc.extractedText,
      );
      setState(() => _documents.insert(0, namedDoc));
      _openResult(namedDoc);
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
                      separatorBuilder: (_, _) => SizedBox(height: R.space(10)),
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
            tooltip: 'Send to child',
            onPressed: _isSendingToChild
                ? null
                : () => _sendDocumentToChild(doc),
            icon: Icon(
              Icons.send_rounded,
              color: primaryGreen,
              size: R.icon(20),
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
