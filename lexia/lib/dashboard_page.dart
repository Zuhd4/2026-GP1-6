import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'add_child_popup.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Increased horizontal and vertical padding for a spacious "Scanner" look
    final double horizontalPad = 22.w;
    final double topPad = 120.h;
    final double bottomPad = 140.h;

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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
                body: Center(child: CircularProgressIndicator()),
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
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  topPad,
                  horizontalPad,
                  bottomPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello $parentName',
                      style: TextStyle(
                        fontSize: 20.sp, // Matched to "Books" header size
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      childrenText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (hasChild)
                      ...snapshot.data!.docs.map(
                        (doc) => Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: _ChildDashboardCard(doc: doc),
                        ),
                      )
                    else
                      const _EmptyStateCard(),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String childName = data['name'] ?? 'Sarah';
    double levelProgress = (displayedLevel > actualLevel) ? 0.0 : 0.4;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: const Color(0xFFD8BDD9).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Profile Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: const Color(0xFFF3EBFF),
                  child: Icon(
                    Icons.person_rounded,
                    size: 26.r,
                    color: const Color(0xFF6A5ACD),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFILE',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.black38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        childName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4F8),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Level $actualLevel/6',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
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

          // Navigation & Fat Progress Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $displayedLevel',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => displayedLevel > 1 ? displayedLevel-- : null,
                          ),
                          icon: Icon(Icons.chevron_left_rounded, size: 20.r),
                          color: (displayedLevel > 1)
                              ? const Color(0xFF6A5ACD)
                              : Colors.black26,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            '$displayedLevel',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11.sp,
                              color: const Color(0xFF6A5ACD),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => displayedLevel < 6 ? displayedLevel++ : null,
                          ),
                          icon: Icon(Icons.chevron_right_rounded, size: 20.r),
                          color: (displayedLevel < 6)
                              ? const Color(0xFF6A5ACD)
                              : Colors.black26,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: 12.h, // Fat Bar
                    backgroundColor: const Color(0xFFF3F4F8),
                    color: const Color(0xFF6A5ACD),
                  ),
                ),
              ],
            ),
          ),

          // 3 Games
          Padding(
            padding: EdgeInsets.all(14.w),
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
                SizedBox(height: 8.h),
                _GameCard(
                  title: 'Word Matching',
                  emoji: '✨',
                  color: const Color(0xFF5B96CA),
                  score: '0/3',
                  status: (displayedLevel > actualLevel)
                      ? 'Locked'
                      : 'Not started',
                ),
                SizedBox(height: 8.h),
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

          // Stories Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stories',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                Text(
                  '2/6',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const _StoryGrid(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _StoryGrid extends StatelessWidget {
  const _StoryGrid();

  @override
  Widget build(BuildContext context) {
    // Stories list with 'done' status for the checkmark overlay
    final List<Map<String, dynamic>> stories = [
      {
        'name': 'Butterfly',
        'emoji': '🦋',
        'color': Color(0xFFE8F5E9),
        'done': true,
      },
      {'name': 'Sky', 'emoji': '✈️', 'color': Color(0xFFE3F2FD), 'done': true},
      {
        'name': 'Stars',
        'emoji': '✨',
        'color': Color(0xFFF3E5F5),
        'done': false,
      },
      {
        'name': 'Moonlight',
        'emoji': '🌙',
        'color': Color(0xFFE1F5FE),
        'done': false,
      },
      {
        'name': 'Dragon',
        'emoji': '🐉',
        'color': Color(0xFFF1F8E9),
        'done': false,
      },
      {
        'name': 'Ocean',
        'emoji': '🐠',
        'color': Color(0xFFE0F7FA),
        'done': false,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: stories[index]['color'],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      stories[index]['emoji'],
                      style: TextStyle(fontSize: 22.sp),
                    ),
                  ),
                ),
                if (stories[index]['done'])
                  Positioned(
                    top: 6.r,
                    right: 6.r,
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: const Color(0xFF59A685),
                        size: 16.r,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            stories[index]['name'],
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3142),
            ),
            maxLines: 1,
          ),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: 12.sp)),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10.sp,
                    color: const Color(0xFF2D3142),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6A5ACD),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.child_care_rounded,
            size: 40.r,
            color: const Color(0xFF6A5ACD),
          ),
          SizedBox(height: 10.h),
          Text(
            'Add a child profile',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddChildPopup(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5ACD),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Add Child',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
