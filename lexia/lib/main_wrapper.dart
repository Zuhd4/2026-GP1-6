import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dashboard_page.dart';
import 'scanner_page.dart';
import 'profile_page.dart';
import 'profile_selection.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // The pages already have their own top/bottom padding to account for these bars
  final List<Widget> _pages = [const DashboardPage(), const ScannerPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body to sit behind the glass footer
      extendBodyBehindAppBar:
          true, // Allows the body to sit behind the glass header
      body: Stack(
        children: [
          // 1. Page Content
          Positioned.fill(child: _pages[_selectedIndex]),

          // 2. Glassmorphism Header (Floating)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false, // Only apply safe area to the top
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E8FD).withOpacity(0.4),
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
                              Icons.logout_rounded,
                              color: const Color(0xFF2D3142).withOpacity(0.6),
                              size: 22.r,
                            ),
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileSelectionPage(),
                              ),
                              (route) => false,
                            ),
                          ),
                          const Spacer(),
                          // Using a hero-like center for the logo
                          Image.asset('assets/Lexia.png', height: 28.h),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.person_outline_rounded,
                              color: const Color(0xFF2D3142),
                              size: 22.r,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // 3. Glassmorphism Footer
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 16.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 72.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5FF).withOpacity(0.4),
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
                  selectedItemColor: const Color(0xFF6A5ACD),
                  unselectedItemColor: const Color(0xFF2D3142).withOpacity(0.4),
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10.sp,
                  ),
                  iconSize: 24.r,
                  items: const [
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
      ),
    );
  }
}
