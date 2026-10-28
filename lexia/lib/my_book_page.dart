import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                          final String name =
                              (data['name'] as String?)?.trim().isNotEmpty ==
                                  true
                              ? data['name'] as String
                              : 'Untitled Document';
                          final String extractedText =
                              (data['extractedText'] as String?) ?? '';
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _DocumentReaderPage(
                                    title: name,
                                    extractedText: extractedText,
                                    useOpenDyslexic: useOpenDyslexic,
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
                                  Container(
                                    width: R.icon(58),
                                    height: R.icon(58),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFE8E4F8,
                                      ).withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(
                                        R.radius(16),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.description_rounded,
                                      size: R.icon(30),
                                      color: primaryPurple.withOpacity(0.75),
                                    ),
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

class _DocumentReaderPage extends StatelessWidget {
  const _DocumentReaderPage({
    required this.title,
    required this.extractedText,
    required this.useOpenDyslexic,
  });

  final String title;
  final String extractedText;
  final bool useOpenDyslexic;

  @override
  Widget build(BuildContext context) {
    R.init(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyBookPage.primaryPurple,
        title: Text(
          title,
          style: AppTypography.getStyle(
            useOpenDyslexic: useOpenDyslexic,
            fontSize: R.text(18),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
        padding: EdgeInsets.all(R.pagePad),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: EdgeInsets.all(R.space(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SelectableText(
              extractedText.trim().isEmpty
                  ? 'No text was detected in this document.'
                  : extractedText,
              style: AppTypography.getStyle(
                useOpenDyslexic: useOpenDyslexic,
                fontSize: R.text(14),
                color: MyBookPage.textDark.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
