import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
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

  // Unified Pop-up logic for all messages
  void _showPopup({
    required BuildContext context,
    required String title,
    required String message,
    required String emoji,
    required Color buttonColor,
  }) {
    final sw = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF9E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: 28.sp)),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.black45,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topMargin = 135.h;
    final double bottomMargin = 140.h;

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
          padding: EdgeInsets.fromLTRB(22.w, topMargin, 22.w, bottomMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Library',
                style: GoogleFonts.montserrat(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w500,
                  color: textDark.withOpacity(0.9),
                ),
              ),
              Text(
                "✨ Unlock stories as you progress",
                style: GoogleFonts.montserrat(
                  fontSize: 12.sp,
                  color: Colors.black45,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 10.h),
              for (int i = 0; i < (stories.length / 2).ceil(); i++)
                _WoodenShelfRow(
                  items: stories.sublist(
                    i * 2,
                    (i * 2 + 2) > stories.length ? stories.length : (i * 2 + 2),
                  ),
                  startIndex: i * 2,
                  onStoryTap: (isLocked, name) {
                    if (isLocked) {
                      _showPopup(
                        context: context,
                        title: 'Story Locked',
                        message:
                            'Complete the previous stories to unlock $name! 🔒',
                        emoji: '🔐',
                        buttonColor: Colors.grey,
                      );
                    } else {
                      _showPopup(
                        context: context,
                        title: 'Coming Soon!',
                        message:
                            'The story "$name" is being prepared for you! 🚀',
                        emoji: '🚀',
                        buttonColor: primaryGreen,
                      );
                    }
                  },
                ),
            ],
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
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: -10.h,
            child: Container(
              width: 0.7.sw,
              height: 12.h,
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
            height: 14.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF1E4D3), Color(0xFFD7C2A9)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(items.length, (index) {
                final globalIndex = startIndex + index;
                final bool locked = globalIndex != 0;
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
            width: 85.w,
            height: 110.h,
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade300 : data['color'],
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
                topLeft: Radius.circular(2.r),
                bottomLeft: Radius.circular(2.r),
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
                  width: 6.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2.r),
                      bottomLeft: Radius.circular(2.r),
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: isLocked ? 0.3 : 1.0,
                    child: Text(
                      data['emoji'],
                      style: TextStyle(fontSize: 35.sp),
                    ),
                  ),
                ),
                if (isLocked)
                  Center(
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: ReadingPage.textDark.withOpacity(0.4),
                      size: 24.r,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data['name'],
            style: GoogleFonts.montserrat(
              fontSize: 11.sp,
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
