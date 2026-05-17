import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';
import 'scanner_page.dart';
import 'profile_page.dart';
import 'profile_selection.dart';
import 'games_page.dart';
import 'reading_page.dart';
import 'my_book_page.dart';
import 'word_page.dart';
import 'child_profile_page.dart';
import 'onboarding_page.dart';

class MainWrapper extends StatefulWidget {
  final bool isChildMode;
  final String? childId;

  const MainWrapper({super.key, this.isChildMode = false, this.childId});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 1;

  final List<Widget> _parentPages = [
    const ScannerPage(),
    const DashboardPage(),
    const WordPage(),
  ];

  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);

  Future<void> _openChildSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      QuerySnapshot snap;

      if (widget.childId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('children')
            .doc(widget.childId)
            .get();

        if (!doc.exists || !mounted) return;
        final data = doc.data() as Map<String, dynamic>;

        _navigateToSettings(
          childId: doc.id,
          name: data['name'] ?? '',
          avatar: data['avatarUrl'] ?? 'assets/lexiaAv.png',
        );
        return;
      }

      snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .limit(1)
          .get();

      if (snap.docs.isEmpty || !mounted) return;

      final doc = snap.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      _navigateToSettings(
        childId: doc.id,
        name: data['name'] ?? '',
        avatar: data['avatarUrl'] ?? 'assets/lexiaAv.png',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load profile settings.")),
        );
      }
    }
  }

  void _navigateToSettings({
    required String childId,
    required String name,
    required String avatar,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChildProfilePage(childId: childId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;

    final List<Widget> currentPages;

    if (widget.isChildMode) {
      if (widget.childId == null || widget.childId!.isEmpty) {
        return const Scaffold(body: Center(child: Text("Child ID missing")));
      }

      currentPages = [
        const ReadingPage(),
        GamesPage(childId: widget.childId!),
        const MyBookPage(),
      ];
    } else {
      currentPages = _parentPages;
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF9F7F8),
      body: Stack(
        children: [
          Positioned.fill(child: currentPages[_selectedIndex]),
          _buildHeader(sw, mq),
        ],
      ),
      bottomNavigationBar: _buildFooter(sw, mq),
    );
  }

  Widget _buildHeader(double sw, MediaQueryData mq) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.055, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    240,
                    230,
                    255,
                  ).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),

                    IconButton(
                      icon: Icon(
                        Icons.logout_rounded,
                        color: textDark.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSelectionPage(),
                        ),
                        (r) => false,
                      ),
                    ),

                    const Spacer(),

                    Image.asset('assets/Lexia.png', height: 26),

                    const Spacer(),

                    if (!widget.isChildMode)
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          color: textDark,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          color: textDark,
                        ),
                        onPressed: _openChildSettings,
                      ),

                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double sw, MediaQueryData mq) {
    final items = widget.isChildMode
        ? [
            {'icon': Icons.menu_book_rounded, 'label': 'Reading'},
            {'icon': Icons.map_rounded, 'label': 'Map'},
            {'icon': Icons.auto_stories_rounded, 'label': 'My Book'},
          ]
        : [
            {'icon': Icons.menu_book_rounded, 'label': 'Books'},
            {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
            {'icon': Icons.manage_search_rounded, 'label': 'Analyzer'},
          ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(sw * 0.055, 0, sw * 0.055, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(230, 217, 249, 1).withOpacity(0.4),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final bool isSelected = _selectedIndex == index;
                  final icon = items[index]['icon'] as IconData;
                  final label = items[index]['label'] as String;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: SizedBox(
                        height: 62,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: isSelected
                                  ? primaryPurple
                                  : textDark.withOpacity(0.4),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? primaryPurple
                                    : textDark.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.isChildMode) {
      _listenToParentSession();
    }
  }

  void _listenToParentSession() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((
      doc,
    ) {
      final data = doc.data();
      final sessionActive = data?['sessionActive'];

      if (sessionActive == false && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
          (route) => false,
        );
      }
    });
  }
}
