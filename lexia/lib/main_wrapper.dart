import 'auth_identity.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'login_screen.dart';
import 'profile_selection.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';
import 'scanner_page.dart';
import 'profile_page.dart';
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

class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  bool _wasBackgrounded = false;
  bool _switchingProfiles = false;
  bool _childSessionHidden = false;

  @override
  void initState() {
    super.initState();
    if (widget.isChildMode) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (widget.isChildMode) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isChildMode || _switchingProfiles) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasBackgrounded = true;
      // Hide child content immediately so it is not exposed upon return.
      if (mounted && !_childSessionHidden) {
        setState(() => _childSessionHidden = true);
      }
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _returnToChildPicker();
    }
  }

  Future<void> _returnToChildPicker() async {
    if (_switchingProfiles || !mounted) return;
    _switchingProfiles = true;
    try {
      final code = await AuthIdentity.storedFamilyCode();
      if (code == null || code.isEmpty) {
        await FirebaseAuth.instance.signOut();
        AuthIdentity.clearChild();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      final cached = await AuthIdentity.storedProfiles(code);
      final children = cached.isNotEmpty
          ? cached
          : await AuthIdentity.loadFamilyProfiles(code);
      await FirebaseAuth.instance.signOut();
      AuthIdentity.clearChild();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              ProfileSelectionPage(familyCode: code, profiles: children),
        ),
        (_) => false,
      );
    } catch (e) {
      debugPrint('LEXIA AUTH - Return to profiles failed: $e');
      // Do not leave the child dashboard accessible after a failed switch.
      await FirebaseAuth.instance.signOut();
      AuthIdentity.clearChild();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } finally {
      _switchingProfiles = false;
    }
  }

  final List<Widget> _parentPages = [
    const ScannerPage(),
    const DashboardPage(),
    const WordPage(),
  ];

  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);

  Future<void> _openChildSettings() async {
    final uid = AuthIdentity.parentUid;

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

  Future<void> _exitChild() async {
    if (!widget.isChildMode) return;
    final code = AuthIdentity.familyCode;
    await FirebaseAuth.instance.signOut();
    AuthIdentity.clearChild();
    if (!mounted) return;
    if (code == null || code.isEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('verifyFamilyCode')
          .call<Map<String, dynamic>>({'familyCode': code});
      final children = (result.data['profiles'] as List<dynamic>? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileSelectionPage(familyCode: code, profiles: children),
        ),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
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
        ReadingPage(childId: widget.childId!),
        GamesPage(childId: widget.childId!),
        MyBookPage(childId: widget.childId!),
      ];
    } else {
      currentPages = _parentPages;
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF9F7F8),
      body: widget.isChildMode && _childSessionHidden
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : Stack(
              children: [
                Positioned.fill(child: currentPages[_selectedIndex]),
                _buildHeader(sw, mq),
              ],
            ),
      bottomNavigationBar: widget.isChildMode && _childSessionHidden
          ? null
          : _buildFooter(sw, mq),
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

                    // No back/logout button in the main dashboard header.
                    const SizedBox(width: 48),

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
                    else ...[
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          color: textDark,
                        ),
                        onPressed: _openChildSettings,
                      ),
                    ],

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

  // Child authentication is independent of the parent session.
  // Never log the child out just because the parent signed out.
}
