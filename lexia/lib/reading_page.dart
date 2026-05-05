import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'responsive_helper.dart';
import 'widgets/lexia_popup.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  final List<Map<String, dynamic>> stories = const [
    {'name': 'Butterfly', 'emoji': '🦋', 'color': Color(0xFFE8F5E9)},
    {'name': 'Sky', 'emoji': '✈️', 'color': Color(0xFFE3F2FD)},
    {'name': 'Stars', 'emoji': '✨', 'color': Color(0xFFF3E5F5)},
    {'name': 'Moon', 'emoji': '🌙', 'color': Color(0xFFE1F5FE)},
    {'name': 'Dragon', 'emoji': '🐉', 'color': Color(0xFFF1F8E9)},
    {'name': 'Ocean', 'emoji': '🐠', 'color': Color(0xFFE0F7FA)},
  ];

  void _showPopup({required BuildContext context}) {
    LexiaPopup.showMessage(
      context: context,
      title: 'Coming Soon!',
      message: 'This feature will be available soon.',
      emoji: '🚀',
      buttonColor: primaryGreen,
      buttonText: 'Got it!',
      barrierDismissible: false,
    );
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
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(21),
                    fontWeight: FontWeight.w500,
                    color: textDark.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: R.space(2)),
                Text(
                  "✨ Unlock stories as you progress",
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(12),
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: R.space(10)),

                for (int i = 0; i < (stories.length / 2).ceil(); i++)
                  _WoodenShelfRow(
                    items: stories.sublist(
                      i * 2,
                      (i * 2 + 2) > stories.length
                          ? stories.length
                          : (i * 2 + 2),
                    ),
                    startIndex: i * 2,
                    onStoryTap: (isLocked, name) {
                      _showPopup(context: context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WoodenShelfRow extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int startIndex;
  final Function(bool, String) onStoryTap;

  const _WoodenShelfRow({
    required this.items,
    required this.startIndex,
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
              children: List.generate(items.length, (index) {
                final bool locked = true;

                return _LibraryBook(
                  data: items[index],
                  isLocked: locked,
                  onTap: () => onStoryTap(locked, items[index]['name']),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBook extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLocked;
  final VoidCallback onTap;

  const _LibraryBook({
    required this.data,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: R.icon(85),
            height: R.space(110),
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade300 : data['color'],
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
              children: [
                Container(
                  width: R.space(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(R.radius(2)),
                      bottomLeft: Radius.circular(R.radius(2)),
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: isLocked ? 0.3 : 1.0,
                    child: Text(
                      data['emoji'],
                      style: TextStyle(fontSize: R.text(35)),
                    ),
                  ),
                ),
                if (isLocked)
                  Center(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: ReadingPage.textDark.withOpacity(0.4),
                      size: R.icon(24),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: R.space(8)),
          Text(
            data['name'],
            style: GoogleFonts.montserrat(
              fontSize: R.text(11),
              fontWeight: FontWeight.w500,
              color: isLocked
                  ? ReadingPage.textDark.withOpacity(0.4)
                  : ReadingPage.textDark.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
