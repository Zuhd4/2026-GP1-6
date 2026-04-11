import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_child_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // --- ULTRA SOFT BRAND COLORS ---
  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB); // Subtle beige tint
  static const Color paleBlush = Color(0xFFFFF9F9); // Subtle pink tint
  static const Color softCream = Color(0xFFFFFAF5); // Warm cream tint

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final double horizontalPad = 22.w;

    // Generous top and bottom margins for the persistent header in MainWrapper
    final double topMargin = 110.h;
    final double bottomMargin = 140.h;

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: primaryPurple),
            ),
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final String parentName = userData?['name'] ?? 'Parent';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('children')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: CircularProgressIndicator(color: primaryPurple),
                ),
              );
            }

            final bool hasChild =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            final List<String> childNames = hasChild
                ? snapshot.data!.docs
                      .map(
                        (doc) =>
                            (doc.data() as Map<String, dynamic>)['name']
                                ?.toString() ??
                            '',
                      )
                      .toList()
                : [];

            String childrenText = childNames.isEmpty
                ? "Track learning journey"
                : "✨ Track ${childNames.join(' & ')}'s journey";

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  // CONSISTENT THREE-POINT SOFT GRADIENT
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
                      // Header Text (Logo removed - persistent in MainWrapper)
                      Text(
                        'Hello $parentName',
                        style: GoogleFonts.montserrat(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w500, // Medium weight
                          color: textDark.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        childrenText,
                        style: GoogleFonts.montserrat(
                          fontSize: 12.sp,
                          color: Colors.black45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: 35.h),

                      _buildPendingRequestCard(context),

                      SizedBox(height: 30.h),

                      if (hasChild)
                        Column(
                          children: snapshot.data!.docs.map((doc) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: 30.h,
                              ), // Generous vertical margin
                              child: _ChildDashboardCard(doc: doc),
                            );
                          }).toList(),
                        )
                      else
                        const _EmptyStateCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8FF),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.vpn_key_rounded,
                  color: primaryPurple.withOpacity(0.7),
                  size: 22.r,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login Request",
                      style: GoogleFonts.montserrat(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                      ),
                    ),
                    Text(
                      "A child is waiting for approval",
                      style: GoogleFonts.montserrat(
                        fontSize: 11.sp,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    "Disapprove",
                    style: GoogleFonts.montserrat(
                      color: Colors.redAccent.withOpacity(0.6),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    "Approve",
                    style: GoogleFonts.montserrat(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildDashboardCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _ChildDashboardCard({required this.doc});

  @override
  State<_ChildDashboardCard> createState() => _ChildDashboardCardState();
}

class _ChildDashboardCardState extends State<_ChildDashboardCard> {
  late int displayedLevel;
  late int actualLevel;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    actualLevel = ((data['level'] as num?)?.toInt() ?? 1).clamp(1, 6);
    displayedLevel = actualLevel;
  }

  Widget _avatarWidget(String? path, {double size = 48}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;
    if (src.endsWith('.svg')) {
      return SvgPicture.asset(
        src,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(src, width: size, height: size, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String childName = data['name'] ?? 'Child';
    final String? avatarUrl = data['avatarUrl'];
    double levelProgress = (displayedLevel > actualLevel) ? 0.0 : 0.4;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _avatarWidget(avatarUrl, size: 50.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: GoogleFonts.montserrat(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4F8),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Level $actualLevel/6',
                          style: GoogleFonts.montserrat(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6A5ACD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $displayedLevel Progress',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => displayedLevel > 1 ? displayedLevel-- : null,
                          ),
                          icon: Icon(Icons.chevron_left_rounded, size: 22.r),
                        ),
                        Text(
                          '$displayedLevel',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 13.sp,
                            color: const Color(0xFF6A5ACD),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => displayedLevel < 6 ? displayedLevel++ : null,
                          ),
                          icon: Icon(Icons.chevron_right_rounded, size: 22.r),
                        ),
                      ],
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: 10.h,
                    backgroundColor: const Color(0xFFF3F4F8),
                    color: const Color(0xFF6A5ACD),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _GameCard(
                  title: 'Letter Scramble',
                  emoji: '🧩',
                  color: const Color(0xFFF1B4AF),
                  score: (displayedLevel > actualLevel) ? '0/3' : '1/3',
                  status: (displayedLevel > actualLevel)
                      ? 'Locked'
                      : 'In Progress',
                ),
                SizedBox(height: 10.h),
                _GameCard(
                  title: 'Word Matching',
                  emoji: '✨',
                  color: const Color(0xFF5B96CA),
                  score: '0/3',
                  status: (displayedLevel > actualLevel)
                      ? 'Locked'
                      : 'Not started',
                ),
                SizedBox(height: 10.h),
                _GameCard(
                  title: 'Listen and Spell',
                  emoji: '🎧',
                  color: const Color(0xFF59A685),
                  score: '0/3',
                  status: (displayedLevel > actualLevel)
                      ? 'Locked'
                      : 'Not started',
                ),
              ],
            ),
          ),

          const _StoryGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title, emoji, score, status;
  final Color color;
  const _GameCard({
    required this.title,
    required this.emoji,
    required this.color,
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 14.sp)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.montserrat(
                    fontSize: 10.sp,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: GoogleFonts.montserrat(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6A5ACD),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryGrid extends StatelessWidget {
  const _StoryGrid();
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stories = [
      {
        'name': 'Butterfly',
        'emoji': '🦋',
        'color': const Color(0xFFE8F5E9),
        'done': true,
      },
      {
        'name': 'Sky',
        'emoji': '✈️',
        'color': const Color(0xFFE3F2FD),
        'done': true,
      },
      {
        'name': 'Stars',
        'emoji': '✨',
        'color': const Color(0xFFF3E5F5),
        'done': false,
      },
      {
        'name': 'Moon',
        'emoji': '🌙',
        'color': const Color(0xFFE1F5FE),
        'done': false,
      },
      {
        'name': 'Dragon',
        'emoji': '🐉',
        'color': const Color(0xFFF1F8E9),
        'done': false,
      },
      {
        'name': 'Ocean',
        'emoji': '🐠',
        'color': const Color(0xFFE0F7FA),
        'done': false,
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            'Recent Stories',
            style: GoogleFonts.montserrat(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3142),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 15.h,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) => Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: stories[index]['color'],
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          stories[index]['emoji'],
                          style: TextStyle(fontSize: 24.sp),
                        ),
                      ),
                      if (stories[index]['done'])
                        Positioned(
                          top: 6.r,
                          right: 6.r,
                          child: Icon(
                            Icons.check_circle,
                            color: const Color(0xFF59A685),
                            size: 18.r,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                stories[index]['name'],
                style: GoogleFonts.montserrat(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF2D3142),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.child_care_rounded,
            size: 48.r,
            color: const Color(0xFF6A5ACD),
          ),
          SizedBox(height: 12.h),
          Text(
            'Add a child profile',
            style: GoogleFonts.montserrat(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddChildPage(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Add Child',
                style: GoogleFonts.montserrat(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
