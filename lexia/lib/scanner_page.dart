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
import 'package:path_provider/path_provider.dart';

import 'responsive_helper.dart';
import 'scan_result_page.dart';
import 'widgets/lexia_popup.dart';

// ============================================================
// SCANNED DOCUMENT MODEL
// ============================================================

class _ScannedDocument {
  final File file;
  final String name;
  final DateTime scannedAt;

  String? extractedText;
  String? parentDocumentId;
  String? parentStoragePath;

  // Store Analyzer results for this document.
  // Example:
  // {
  //   "beautiful": "hard",
  //   "happy": "medium",
  //   "cat": "easy"
  // }
  final Map<String, String> difficultyByWord = <String, String>{};

  _ScannedDocument({
    required this.file,
    required this.name,
    required this.scannedAt,
    this.extractedText,
    this.parentDocumentId,
    this.parentStoragePath,
  });
}

// ============================================================
// SCANNER PAGE
// ============================================================

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
  bool _isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadParentDocuments();
  }

  Future<void> _loadParentDocuments() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoadingDocuments = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('parentDocuments')
          .orderBy('createdAt', descending: true)
          .get();
      final directory = await getTemporaryDirectory();
      final restored = <_ScannedDocument>[];
      for (final entry in snapshot.docs) {
        final data = entry.data();
        final storagePath = data['imageStoragePath'] as String?;
        if (storagePath == null || storagePath.isEmpty) continue;
        try {
          final file = File('${directory.path}/lexia_parent_${entry.id}.jpg');
          await FirebaseStorage.instance.ref(storagePath).writeToFile(file);
          final createdAt = data['createdAt'];
          final doc = _ScannedDocument(
            file: file,
            name: (data['name'] ?? 'Untitled Document').toString(),
            scannedAt: createdAt is Timestamp
                ? createdAt.toDate()
                : DateTime.now(),
            extractedText: (data['extractedText'] ?? '').toString(),
            parentDocumentId: entry.id,
            parentStoragePath: storagePath,
          );
          final rawMap = data['difficultyByWord'];
          if (rawMap is Map) {
            rawMap.forEach((key, value) {
              if (key is String && value is String) {
                doc.difficultyByWord[_normalizeWord(key)] = value.toLowerCase();
              }
            });
          }
          restored.add(doc);
        } catch (error) {
          debugPrint('RESTORE PARENT DOCUMENT ${entry.id} ERROR: $error');
        }
      }
      if (mounted) {
        setState(() {
          final existingIds = _documents.map((d) => d.parentDocumentId).toSet();
          _documents.addAll(
            restored.where((d) => !existingIds.contains(d.parentDocumentId)),
          );
          _documents.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        });
      }
    } catch (error, stackTrace) {
      debugPrint('LOAD PARENT DOCUMENTS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _saveParentDocument(_ScannedDocument doc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Parent must be signed in');
    final destination = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('parentDocuments')
        .doc();
    final path = 'users/$uid/parentDocuments/${destination.id}.jpg';
    final storageRef = FirebaseStorage.instance.ref(path);
    await storageRef.putFile(doc.file);
    try {
      await destination.set({
        'name': doc.name,
        'extractedText': doc.extractedText ?? '',
        'difficultyByWord': Map<String, String>.from(doc.difficultyByWord),
        'imageStoragePath': path,
        'createdAt': FieldValue.serverTimestamp(),
      });
      doc.parentDocumentId = destination.id;
      doc.parentStoragePath = path;
    } catch (_) {
      try {
        await storageRef.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _updateParentAnalysis(_ScannedDocument doc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = doc.parentDocumentId;
    if (uid == null || id == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('parentDocuments')
          .doc(id)
          .update({
            'difficultyByWord': Map<String, String>.from(doc.difficultyByWord),
          });
    } catch (error) {
      debugPrint('SAVE PARENT ANALYSIS ERROR: $error');
    }
  }

  bool _isProcessing = false;
  bool _isSendingToChild = false;

  final String _sendingChildName = '';

  StreamController<double>? _uploadProgressStream;

  // ============================================================
  // WORD NORMALIZATION
  // ============================================================

  static final RegExp _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)?");

  String _normalizeWord(String word) {
    return word.toLowerCase().replaceAll('’', "'");
  }

  // Returns all unique words in the scanned document.
  Set<String> _extractUniqueWords(String text) {
    return _wordPattern
        .allMatches(text)
        .map((match) => _normalizeWord(match.group(0)!))
        .toSet();
  }

  // Check whether every word has a difficulty classification.
  bool _isAnalysisComplete(_ScannedDocument doc) {
    final words = _extractUniqueWords(doc.extractedText ?? '');

    for (final word in words) {
      final difficulty = doc.difficultyByWord[word];

      if (difficulty != 'easy' &&
          difficulty != 'medium' &&
          difficulty != 'hard') {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // SEND PROGRESS DIALOG
  // ============================================================

  Future<void> _showSendProgressDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
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
              Expanded(child: Text('Updating recipients')),
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
                    'Updating document access...',
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
      ),
    );
  }

  // ============================================================
  // SEND DOCUMENT TO CHILD
  // ============================================================

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
    final parentDocumentId = doc.parentDocumentId;
    if (parentDocumentId == null) {
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Document not ready',
          message: 'Please save the document before managing recipients.',
          emoji: '⚠️',
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

      // Match by parentDocumentId, never document name.
      final existingRecipients =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final child in children.docs) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(parentId)
            .collection('children')
            .doc(child.id)
            .collection('sharedDocuments')
            .where('parentDocumentId', isEqualTo: parentDocumentId)
            .get();
        if (snapshot.docs.isNotEmpty) {
          existingRecipients[child.id] = snapshot.docs.first;
        }
      }
      if (!mounted) return;

      final selectedChildIds = await showDialog<List<String>>(
        context: context,
        builder: (dialogContext) {
          final selected = existingRecipients.keys.toSet();
          return StatefulBuilder(
            builder: (dialogContext, refreshSelection) => Dialog(
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
                      'Send to children',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select who can access “${doc.name}”',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uncheck a child to remove the document from My Book.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.black45,
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
                            child: CheckboxListTile(
                              value: selected.contains(child.id),
                              activeColor: primaryPurple,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: const CircleAvatar(
                                backgroundColor: Color(0xFFE6DDF7),
                                child: Icon(
                                  Icons.face_rounded,
                                  color: primaryPurple,
                                ),
                              ),
                              title: Text(
                                childName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              onChanged: (checked) => refreshSelection(() {
                                if (checked == true) {
                                  selected.add(child.id);
                                } else {
                                  selected.remove(child.id);
                                }
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.montserrat(color: textDark),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, selected.toList()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Save changes',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
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
      );
      if (!mounted || selectedChildIds == null) return;

      final selectedSet = selectedChildIds.toSet();
      final existingSet = existingRecipients.keys.toSet();
      final newRecipients = selectedSet.difference(existingSet);
      final revokedRecipients = existingSet.difference(selectedSet);
      if (newRecipients.isEmpty && revokedRecipients.isEmpty) return;

      if (newRecipients.isNotEmpty && !_isAnalysisComplete(doc)) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Analysis not finished',
          message:
              'Open the document and wait until all words are analyzed before sending.',
          emoji: '🔎',
          buttonText: 'Okay',
        );
        return;
      }

      if (revokedRecipients.isNotEmpty) {
        final revokedNames = children.docs
            .where((child) => revokedRecipients.contains(child.id))
            .map((child) => (child.data()['name'] ?? 'Child').toString())
            .toList();
        final confirmed = await LexiaPopup.showConfirm(
          context: context,
          title: 'Remove access?',
          message: revokedNames.length == 1
              ? 'Remove “${doc.name}” from ${revokedNames.first}\'s My Book?'
              : 'Remove “${doc.name}” from ${revokedNames.join(", ")}?',
          confirmText: 'Remove access',
          confirmColor: Colors.redAccent,
          icon: Icons.person_remove_alt_1_rounded,
          iconColor: Colors.redAccent,
        );
        if (!mounted || !confirmed) return;
      }

      final totalOperations = newRecipients.length + revokedRecipients.length;
      var completedOperations = 0;
      var successfullySent = 0;
      var successfullyRevoked = 0;
      final failedActions = <String>[];
      _uploadProgressStream = StreamController<double>.broadcast();
      setState(() => _isSendingToChild = true);
      final progressDialog = _showSendProgressDialog();

      try {
        for (final child in children.docs) {
          if (!newRecipients.contains(child.id)) continue;
          final childName = (child.data()['name'] ?? 'Child').toString();
          final destination = FirebaseFirestore.instance
              .collection('users')
              .doc(parentId)
              .collection('children')
              .doc(child.id)
              .collection('sharedDocuments')
              .doc();
          final path =
              'users/$parentId/children/${child.id}/sharedDocuments/${destination.id}.jpg';
          final storageRef = FirebaseStorage.instance.ref(path);
          var uploaded = false;
          try {
            final upload = storageRef.putFile(doc.file);
            final subscription = upload.snapshotEvents.listen((snapshot) {
              if (snapshot.totalBytes <= 0 ||
                  (_uploadProgressStream?.isClosed ?? true))
                return;
              final childProgress =
                  snapshot.bytesTransferred / snapshot.totalBytes;
              _uploadProgressStream?.add(
                (((completedOperations + childProgress) / totalOperations) *
                        0.99)
                    .clamp(0.0, 0.99),
              );
            });
            try {
              await upload;
              uploaded = true;
            } finally {
              await subscription.cancel();
            }
            await destination.set({
              'name': doc.name,
              'extractedText': doc.extractedText ?? '',
              'difficultyByWord': Map<String, String>.from(
                doc.difficultyByWord,
              ),
              'imageStoragePath': path,
              'createdAt': FieldValue.serverTimestamp(),
              'sentBy': parentId,
              'parentDocumentId': parentDocumentId,
            });
            successfullySent++;
          } catch (error, stackTrace) {
            debugPrint('SEND TO $childName ERROR: $error');
            debugPrintStack(stackTrace: stackTrace);
            failedActions.add('Could not send to $childName');
            if (uploaded) {
              try {
                await storageRef.delete();
              } catch (cleanupError) {
                debugPrint('SEND CLEANUP ERROR: $cleanupError');
              }
            }
          }
          completedOperations++;
          if (!(_uploadProgressStream?.isClosed ?? true)) {
            _uploadProgressStream?.add(
              ((completedOperations / totalOperations) * 0.99).clamp(0.0, 0.99),
            );
          }
        }

        for (final childId in revokedRecipients) {
          final matches = children.docs.where((child) => child.id == childId);
          final childName = matches.isNotEmpty
              ? (matches.first.data()['name'] ?? 'Child').toString()
              : childId;
          final childDocument = existingRecipients[childId];
          if (childDocument == null) {
            failedActions.add('Could not remove access from $childName');
          } else {
            final imageStoragePath =
                childDocument.data()['imageStoragePath'] as String?;
            try {
              // Delete child's Firestore record first to hide it from My Book.
              await childDocument.reference.delete();
              successfullyRevoked++;
              if (imageStoragePath != null && imageStoragePath.isNotEmpty) {
                try {
                  await FirebaseStorage.instance.ref(imageStoragePath).delete();
                } catch (storageError) {
                  debugPrint('REVOKE STORAGE CLEANUP ERROR: $storageError');
                }
              }
            } catch (error, stackTrace) {
              debugPrint('REVOKE FROM $childName ERROR: $error');
              debugPrintStack(stackTrace: stackTrace);
              failedActions.add('Could not remove access from $childName');
            }
          }
          completedOperations++;
          if (!(_uploadProgressStream?.isClosed ?? true)) {
            _uploadProgressStream?.add(
              ((completedOperations / totalOperations) * 0.99).clamp(0.0, 0.99),
            );
          }
        }

        if (!(_uploadProgressStream?.isClosed ?? true)) {
          _uploadProgressStream?.add(1.0);
        }
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        await progressDialog;
        if (!mounted) return;
        LexiaPopup.showMessage(
          context: context,
          title: failedActions.isEmpty
              ? 'Access updated!'
              : 'Some changes failed',
          message: failedActions.isEmpty
              ? '$successfullySent sent, $successfullyRevoked removed. Your document is still saved in Documents.'
              : '$successfullySent sent, $successfullyRevoked removed. ${failedActions.join(". ")}.',
          emoji: failedActions.isEmpty ? '💌' : '⚠️',
          buttonText: 'Done',
          buttonColor: failedActions.isEmpty ? primaryGreen : Colors.redAccent,
        );
      } catch (error, stackTrace) {
        debugPrint('UPDATE RECIPIENTS ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          await progressDialog;
          if (mounted) {
            LexiaPopup.showMessage(
              context: context,
              title: 'Could not update access',
              message: 'Please check your connection and try again.',
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
      debugPrint('LOAD RECIPIENTS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Could not load recipients',
          message: 'Please check your connection and try again.',
          emoji: '⚠️',
          buttonText: 'Okay',
        );
      }
    }
  }

  // ============================================================
  // DOCUMENT NAMING
  // ============================================================

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

              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _textRecognizer.close();
    _languageIdentifier.close();
    super.dispose();
  }

  // ============================================================
  // SCAN / UPLOAD IMAGE
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (picked == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        return;
      }

      final file = File(picked.path);

      final doc = _ScannedDocument(
        file: file,
        name: 'Scan ${_documents.length + 1}',
        scannedAt: DateTime.now(),
      );

      // --------------------------------------------------------
      // RUN OCR
      // --------------------------------------------------------

      final inputImage = InputImage.fromFilePath(file.path);

      final RecognizedText recognized = await _textRecognizer.processImage(
        inputImage,
      );

      // Keep English lines only.
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

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (!hasText) {
        LexiaPopup.showMessage(
          context: context,
          title: 'No text detected',
          message:
              'We couldn\'t find any readable English text in that image. Try again with a clearer shot of the page.',
          emoji: '🔍',
          buttonColor: Colors.redAccent.withOpacity(0.8),
          buttonText: 'Try again',
        );
        return;
      }

      // --------------------------------------------------------
      // ASK DOCUMENT NAME
      // --------------------------------------------------------

      final name = await _askDocumentName(doc.name);

      if (!mounted || name == null) return;

      final namedDoc = _ScannedDocument(
        file: doc.file,
        name: name,
        scannedAt: doc.scannedAt,
        extractedText: doc.extractedText,
      );
      try {
        await _saveParentDocument(namedDoc);
      } catch (error, stackTrace) {
        debugPrint('SAVE PARENT DOCUMENT ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          LexiaPopup.showMessage(
            context: context,
            title: 'Could not save document',
            message:
                'The scan could not be saved to your Documents. Please check your connection and Firebase permissions, then try again.',
            emoji: '⚠️',
            buttonText: 'Okay',
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _documents.insert(0, namedDoc);
      });
      // Open Analyzer automatically.
      _openResult(namedDoc);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

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

  // ============================================================
  // OPEN ANALYZER RESULTS
  // ============================================================

  void _openResult(_ScannedDocument doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultPage(
          documentName: doc.name,
          extractedText: doc.extractedText ?? '',
          // NEW: Receive difficulty results from Analyzer.
          onDifficultiesUpdated: (results) {
            doc.difficultyByWord
              ..clear()
              ..addAll(
                results.map(
                  (key, value) =>
                      MapEntry(_normalizeWord(key), value.toLowerCase()),
                ),
              );
            debugPrint(
              'ANALYZER RESULTS SAVED: '
              '${doc.difficultyByWord.length} words',
            );
            _updateParentAnalysis(doc);
          },
        ),
      ),
    );
  }

  // ============================================================
  // SHARE DOCUMENT
  // ============================================================

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

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

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
    if (!confirmed || !mounted) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && doc.parentDocumentId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('parentDocuments')
            .doc(doc.parentDocumentId)
            .delete();
      }
      if (doc.parentStoragePath != null) {
        try {
          await FirebaseStorage.instance.ref(doc.parentStoragePath!).delete();
        } catch (error) {
          debugPrint('DELETE PARENT IMAGE ERROR: $error');
        }
      }
      if (mounted) setState(() => _documents.remove(doc));
    } catch (error) {
      if (mounted) {
        LexiaPopup.showMessage(
          context: context,
          title: 'Could not remove',
          message: 'Please try again.',
          emoji: '⚠️',
          buttonText: 'Okay',
        );
      }
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

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

    return '${months[dt.month - 1]} '
        '${dt.day} · $hour:$minute $period';
  }

  // ============================================================
  // BUILD
  // ============================================================

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

              // ==================================================
              // SCAN / UPLOAD CARD
              // ==================================================
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

              // ==================================================
              // DOCUMENTS
              // ==================================================
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

              _isLoadingDocuments
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryPurple),
                    )
                  : _documents.isEmpty
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

  // ============================================================
  // EMPTY DOCUMENTS STATE
  // ============================================================

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

  // ============================================================
  // DOCUMENT TILE
  // ============================================================

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

          // Send to child
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

          // Share
          IconButton(
            onPressed: () => _shareDocument(doc),
            icon: Icon(
              Icons.ios_share_rounded,
              color: primaryPurple,
              size: R.icon(20),
            ),
          ),

          // Delete
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

  // ============================================================
  // BUTTON
  // ============================================================

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
