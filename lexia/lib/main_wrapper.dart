import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dashboard_page.dart';
import 'scanner_page.dart';
import 'profile_page.dart';
import 'profile_selection.dart';
import 'games_page.dart';
import 'reading_page.dart';
import 'my_book_page.dart';

class MainWrapper extends StatefulWidget {
  final bool isChildMode;
  const MainWrapper({super.key, this.isChildMode = false});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _parentPages = [
    const DashboardPage(),
    const ScannerPage(),
  ];
  final List<Widget> _childPages = [
    const GamesPage(),
    const ReadingPage(),
    const MyBookPage(),
  ];

  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color textDark = Color(0xFF2D3142);

  @override
  Widget build(BuildContext context) {
    final List<Widget> currentPages = widget.isChildMode
        ? _childPages
        : _parentPages;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF9F7F8),
      body: Stack(
        children: [
          Positioned.fill(child: currentPages[_selectedIndex]),
          _buildHeader(),
        ],
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(
                    230,
                    217,
                    249,
                    1,
                  ).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: Icon(
                        widget.isChildMode
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.logout_rounded,
                        color: textDark.withOpacity(0.6),
                        size: 22.r,
                      ),
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSelectionPage(),
                        ),
                        (route) => false,
                      ),
                    ),
                    const Spacer(),
                    Image.asset('assets/Lexia.png', height: 28.h),
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
                      SizedBox(width: 48.w),
                    SizedBox(width: 8.w),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 16.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(230, 217, 249, 1).withOpacity(0.4),
                borderRadius: BorderRadius.circular(35.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedItemColor: primaryPurple,
                unselectedItemColor: textDark.withOpacity(0.4),
                type: BottomNavigationBarType.fixed,
                items: widget.isChildMode
                    ? const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.videogame_asset_rounded),
                          label: 'Games',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book_rounded),
                          label: 'Reading',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.auto_stories_rounded),
                          label: 'My Book',
                        ),
                      ]
                    : const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.grid_view_rounded),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book_rounded),
                          label: 'Books',
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
