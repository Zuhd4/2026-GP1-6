import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final bool useOpenDyslexic;

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
    this.useOpenDyslexic = false,
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
            useOpenDyslexic: data['useOpenDyslexicFont'] == true,
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

      // Repair previously deleted parent documents that were left in My Book.
      // Use the full Firestore snapshot, NOT restored images, as the source of
      // truth: a temporary image download failure must never revoke access.
      await _cleanUpOrphanedChildShares(
        uid,
        snapshot.docs.map((entry) => entry.id).toSet(),
      );
    } catch (error, stackTrace) {
      debugPrint('LOAD PARENT DOCUMENTS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isLoadingDocuments = false);
    }
  }

  // Remove a shared document from the child's My Book immediately.
  // Deleting its Firestore record updates the child's live StreamBuilder.
  // The Storage image is deleted afterward (best effort).
  Future<void> _removeChildShare(
    QueryDocumentSnapshot<Map<String, dynamic>> sharedDoc,
  ) async {
    final imagePath = sharedDoc.data()['imageStoragePath'] as String?;
    await sharedDoc.reference.delete();
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        await FirebaseStorage.instance.ref(imagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') {
          debugPrint('REMOVE SHARED IMAGE ERROR: $error');
        }
      } catch (error) {
        debugPrint('REMOVE SHARED IMAGE ERROR: $error');
      }
    }
  }

  // One-time reconciliation on parent Books load for documents deleted
  // before cascading deletion was implemented. No legacy records lacking
  // parentDocumentId are touched.
  Future<void> _cleanUpOrphanedChildShares(
    String parentUid,
    Set<String> validParentDocumentIds,
  ) async {
    try {
      final children = await FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .get();
      for (final child in children.docs) {
        try {
          final shares = await child.reference
              .collection('sharedDocuments')
              .get();
          for (final sharedDoc in shares.docs) {
            final parentDocId = sharedDoc.data()['parentDocumentId'];
            if (parentDocId is String &&
                parentDocId.isNotEmpty &&
                !validParentDocumentIds.contains(parentDocId)) {
              try {
                await _removeChildShare(sharedDoc);
                debugPrint('REMOVED OLD ORPHAN SHARE: ${sharedDoc.id}');
              } catch (error) {
                debugPrint('ORPHAN SHARE CLEANUP FAILED: $error');
              }
            }
          }
        } catch (error) {
          debugPrint('CHILD SHARE CLEANUP FAILED (${child.id}): $error');
        }
      }
    } catch (error) {
      debugPrint('ORPHAN CLEANUP COULD NOT LOAD CHILDREN: $error');
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
        'useOpenDyslexicFont': doc.useOpenDyslexic,
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
  bool _isPreparingDocument = false;
  bool _isSendingToChild = false;
  bool _isDeletingDocument = false;

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

  // Use the child's selected profile avatar in the recipient picker.
  // Lexia stores avatarUrl as an asset path (PNG or SVG).
  Widget _childAvatar(String? avatarUrl) {
    final source = (avatarUrl == null || avatarUrl.trim().isEmpty)
        ? 'assets/lexiaAv.png'
        : avatarUrl.trim();

    Widget fallback() => Image.asset(
      'assets/lexiaAv.png',
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person_rounded, color: primaryPurple),
    );

    Widget picture;
    if (source.toLowerCase().endsWith('.svg')) {
      picture = source.startsWith('http://') || source.startsWith('https://')
          ? SvgPicture.network(
              source,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => fallback(),
            )
          : SvgPicture.asset(
              source,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => fallback(),
            );
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      picture = Image.network(
        source,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    } else {
      picture = Image.asset(
        source,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE6DDF7),
      child: ClipOval(child: picture),
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
                              secondary: _childAvatar(
                                child.data()['avatarUrl']?.toString(),
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
              'useOpenDyslexicFont': doc.useOpenDyslexic,
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

  Future<_DocumentNameChoice?> _askDocumentName(String suggestedName) {
    if (!mounted) return Future.value(null);
    R.init(context);
    return showDialog<_DocumentNameChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _DocumentNameDialog(suggestedName: suggestedName),
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

      final choice = await _askDocumentName(doc.name);

      if (!mounted || choice == null) return;

      final namedDoc = _ScannedDocument(
        file: doc.file,
        name: choice.name,
        scannedAt: doc.scannedAt,
        extractedText: doc.extractedText,
        useOpenDyslexic: choice.useOpenDyslexic,
      );
      setState(() => _isPreparingDocument = true);
      try {
        await _saveParentDocument(namedDoc);
      } catch (error, stackTrace) {
        debugPrint('SAVE PARENT DOCUMENT ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          setState(() => _isPreparingDocument = false);
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
        _isPreparingDocument = false;
      });
      // Open Analyzer automatically.
      _openResult(namedDoc);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isPreparingDocument = false;
      });

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
          useOpenDyslexic: doc.useOpenDyslexic,
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

  // Share analyzed results as print-friendly PNG pages (2:3 aspect ratio).
  // Each page has fixed margins so wide OpenDyslexic letters cannot be
  // cropped by Android's 4x6 print preview.
  Future<void> _shareDocument(_ScannedDocument doc) async {
    if ((doc.extractedText ?? '').trim().isEmpty) {
      await LexiaPopup.showMessage(
        context: context,
        title: 'No analyzed text',
        message: 'Open the document to analyze its text before exporting.',
        icon: Icons.info_outline_rounded,
        buttonColor: primaryPurple,
      );
      return;
    }
    if (!_isAnalysisComplete(doc)) {
      await LexiaPopup.showMessage(
        context: context,
        title: 'Analysis not finished',
        message:
            'Open the document and wait until all words are analyzed before exporting.',
        icon: Icons.manage_search_rounded,
        buttonColor: primaryPurple,
      );
      return;
    }

    try {
      const double pageWidth = 1080;
      const double pageHeight = 1620; // 4x6 aspect ratio (portrait)
      const double left = 84;
      const double right = pageWidth - 84;
      const double bodyTop = 292;
      const double bodyBottom = pageHeight - 125;
      const double bodyFontSize = 29;
      final double lineHeight = doc.useOpenDyslexic ? 59 : 51;

      final TextStyle bodyStyle = doc.useOpenDyslexic
          ? const TextStyle(
              fontFamily: 'OpenDyslexic',
              fontSize: bodyFontSize,
              color: textDark,
            )
          : GoogleFonts.montserrat(fontSize: bodyFontSize, color: textDark);
      final highlightedStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);

      TextPainter measure(String value, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: value, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        painter.layout();
        return painter;
      }

      final pages = <ui.PictureRecorder>[];
      ui.PictureRecorder? recorder;
      Canvas? canvas;
      double x = left;
      double y = bodyTop;

      void beginPage() {
        recorder = ui.PictureRecorder();
        canvas = Canvas(recorder!);
        canvas!.drawRect(
          const Rect.fromLTWH(0, 0, pageWidth, pageHeight),
          Paint()..color = Colors.white,
        );
        final titleStyle = GoogleFonts.montserrat(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: textDark,
        );
        // Titles can be long. Limit width to the same safe margins.
        final title = TextPainter(
          text: TextSpan(text: doc.name, style: titleStyle),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: right - left);
        title.paint(canvas!, const Offset(left, 42));
        measure(
          'Lexia - Word Difficulty Analysis',
          GoogleFonts.montserrat(fontSize: 23, color: primaryPurple),
        ).paint(canvas!, const Offset(left, 155));

        canvas!.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(left, 225, 26, 26),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFFFFF176),
        );
        measure(
          'Medium',
          GoogleFonts.montserrat(fontSize: 22, color: textDark),
        ).paint(canvas!, const Offset(left + 39, 222));
        canvas!.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(280, 225, 26, 26),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFFFFB74D),
        );
        measure(
          'Hard',
          GoogleFonts.montserrat(fontSize: 22, color: textDark),
        ).paint(canvas!, const Offset(319, 222));
        x = left;
        y = bodyTop;
      }

      void finishPage() {
        if (recorder != null) {
          measure(
            'Page ${pages.length + 1}',
            GoogleFonts.montserrat(fontSize: 22, color: Colors.black54),
          ).paint(canvas!, const Offset(left, pageHeight - 77));
          pages.add(recorder!);
          recorder = null;
          canvas = null;
        }
      }

      void nextLine() {
        x = left;
        y += lineHeight;
        if (y + lineHeight > bodyBottom) {
          finishPage();
          beginPage();
        }
      }

      beginPage();
      for (final line in doc.extractedText!.split('\n')) {
        if (line.trim().isEmpty) {
          nextLine();
          continue;
        }
        for (final tokenMatch in RegExp(r'\S+').allMatches(line)) {
          final token = tokenMatch.group(0)!;
          final word = _wordPattern.firstMatch(token)?.group(0);
          final difficulty = word == null
              ? null
              : doc.difficultyByWord[_normalizeWord(word)];
          final Color? highlight = difficulty == 'medium'
              ? const Color(0xFFFFF176)
              : difficulty == 'hard'
              ? const Color(0xFFFFB74D)
              : null;
          final painter = measure(
            token,
            highlight == null ? bodyStyle : highlightedStyle,
          );
          final space = measure(' ', bodyStyle).width;
          final width = painter.width;
          if (x > left && x + width > right) nextLine();
          // Make unusually long OCR tokens fit the page instead of clipping.
          final scale = width > right - left ? (right - left) / width : 1.0;
          if (highlight != null) {
            canvas!.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  x - 3,
                  y - 3,
                  width * scale + 6,
                  painter.height + 6,
                ),
                const Radius.circular(9),
              ),
              Paint()..color = highlight,
            );
          }
          canvas!.save();
          canvas!.translate(x, y);
          canvas!.scale(scale, 1);
          painter.paint(canvas!, Offset.zero);
          canvas!.restore();
          x += width * scale + space;
        }
        nextLine();
      }
      finishPage();

      if (pages.length > 40) {
        await LexiaPopup.showMessage(
          context: context,
          title: 'Document too long',
          message: 'This document is too long to export as images.',
          icon: Icons.info_outline_rounded,
          buttonColor: primaryPurple,
        );
        return;
      }

      final directory = await getTemporaryDirectory();
      final safeName = doc.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final name = safeName.isEmpty ? 'Lexia_Result' : safeName;
      final attachments = <XFile>[];
      for (var i = 0; i < pages.length; i++) {
        final pageRecorder = pages[i];
        final picture = pageRecorder.endRecording();
        final image = await picture.toImage(
          pageWidth.toInt(),
          pageHeight.toInt(),
        );
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        if (data == null) throw StateError('Could not encode analyzed image');
        final file = File(
          '${directory.path}/${name}_Lexia_Analysis_${i + 1}.png',
        );
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
        attachments.add(XFile(file.path, mimeType: 'image/png'));
      }
      await Share.shareXFiles(
        attachments,
        text: 'Lexia analyzed results - ${doc.name}',
      );
    } catch (error, stackTrace) {
      debugPrint('EXPORT ANALYSIS IMAGE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      await LexiaPopup.showMessage(
        context: context,
        title: 'Could not export results',
        message: 'Please try again.',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        buttonColor: primaryPurple,
      );
    }
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> _deleteDocument(_ScannedDocument doc) async {
    if (_isDeletingDocument) return;

    final confirmed = await LexiaPopup.showConfirm(
      context: context,
      title: 'Remove document?',
      message:
          'This will remove "${doc.name}" from your Documents and from every child you shared it with.',
      confirmText: 'Remove',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.redAccent,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeletingDocument = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    // Keep the loading popup visible for the entire deletion operation.
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: primaryPurple,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Deleting document',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Removing the document from your Books and your children’s My Book...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    bool failed = false;
    try {
      final parentUid = FirebaseAuth.instance.currentUser?.uid;
      final parentDocId = doc.parentDocumentId;
      if (parentUid == null || parentDocId == null) {
        throw StateError('The parent document is not saved.');
      }

      final parentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid);
      final children = await parentRef.collection('children').get();

      // Remove child references first. If any Firestore deletion fails,
      // keep the parent document so this operation can be retried.
      for (final child in children.docs) {
        final matches = await child.reference
            .collection('sharedDocuments')
            .where('parentDocumentId', isEqualTo: parentDocId)
            .get();
        for (final sharedDoc in matches.docs) {
          await _removeChildShare(sharedDoc);
        }
      }

      await parentRef.collection('parentDocuments').doc(parentDocId).delete();
      if (doc.parentStoragePath != null && doc.parentStoragePath!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(doc.parentStoragePath!).delete();
        } on FirebaseException catch (error) {
          if (error.code != 'object-not-found') {
            debugPrint('DELETE PARENT IMAGE ERROR: $error');
          }
        } catch (error) {
          debugPrint('DELETE PARENT IMAGE ERROR: $error');
        }
      }
      if (mounted) setState(() => _documents.remove(doc));
    } catch (error, stackTrace) {
      failed = true;
      debugPrint('DELETE DOCUMENT AND CHILD SHARES ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      // Close the loading popup even when deletion fails.
      if (navigator.mounted && navigator.canPop()) navigator.pop();
      if (mounted) setState(() => _isDeletingDocument = false);
    }

    if (failed && mounted) {
      await LexiaPopup.showMessage(
        context: context,
        title: 'Could not remove completely',
        message:
            'Some documents could not be removed. Please check your connection and try again.',
        emoji: '⚠️',
        buttonText: 'Okay',
      );
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
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                          ),
                        )
                      : _documents.isEmpty
                      ? _emptyDocumentsState()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documents.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: R.space(10)),
                          itemBuilder: (context, index) =>
                              _documentTile(_documents[index]),
                        ),
                ],
              ),
            ),
          ),
          if (_isPreparingDocument)
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
                      padding: EdgeInsets.symmetric(horizontal: R.space(24)),
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
                            ),
                            SizedBox(height: R.space(20)),
                            Text(
                              'Preparing document',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(20),
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: R.space(8)),
                            Text(
                              'Saving your scan before analyzing the text...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(12),
                                color: Colors.black45,
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

// ============================================================
// DOCUMENT NAME DIALOG
// ============================================================

class _DocumentNameChoice {
  const _DocumentNameChoice(this.name, this.useOpenDyslexic);
  final String name;
  final bool useOpenDyslexic;
}

class _DocumentNameDialog extends StatefulWidget {
  final String suggestedName;
  const _DocumentNameDialog({required this.suggestedName});

  @override
  State<_DocumentNameDialog> createState() => _DocumentNameDialogState();
}

class _DocumentNameDialogState extends State<_DocumentNameDialog> {
  late final TextEditingController _controller;
  bool _useOpenDyslexic = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      Navigator.pop(context, _DocumentNameChoice(name, _useOpenDyslexic));
    }
  }

  @override
  Widget build(BuildContext context) {
    // To match the responsive logic, use R static from outer context
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: R.space(16),
          vertical: R.space(24),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(24)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: R.maxContentWidth < 420 ? R.maxContentWidth : 420,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(R.space(22)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Removed icon and SizedBox(height: R.space(16)),
                  Text(
                    'Name your document',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(20),
                      fontWeight: FontWeight.w500,
                      color: _ScannerPageState.textDark,
                    ),
                  ),
                  SizedBox(height: R.space(8)),
                  Text(
                    'Enter a name for your document',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(12),
                      color: Colors.black45,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: R.space(20)),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.montserrat(
                      fontSize: R.text(13),
                      color: _ScannerPageState.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Document name',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: R.text(14),
                        color: Colors.black45,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.radius(18)),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.radius(18)),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.radius(18)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: R.space(20),
                        vertical: R.space(20),
                      ),
                    ),
                    onSubmitted: (value) {
                      final name = value.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(
                          context,
                          _DocumentNameChoice(name, _useOpenDyslexic),
                        );
                      }
                    },
                  ),
                  SizedBox(height: R.space(3)),
                  CheckboxListTile(
                    value: _useOpenDyslexic,
                    onChanged: (value) => setState(() {
                      _useOpenDyslexic = value ?? false;
                    }),
                    activeColor: _ScannerPageState.primaryPurple,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Dyslexia friendly font',
                      style: GoogleFonts.montserrat(
                        fontSize: R.text(12),
                        color: _ScannerPageState.textDark,
                      ),
                    ),
                  ),
                  SizedBox(height: R.space(14)),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.montserrat(
                              fontSize: R.text(12),
                              fontWeight: FontWeight.w500,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: R.space(10)),
                      Expanded(
                        child: SizedBox(
                          height: R.buttonH(52),
                          child: ElevatedButton(
                            onPressed: _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _ScannerPageState.primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  R.radius(18),
                                ),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: GoogleFonts.montserrat(
                                fontSize: R.text(12),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
