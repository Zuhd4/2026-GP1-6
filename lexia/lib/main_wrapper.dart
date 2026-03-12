import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'scanner_page.dart';
import 'profile_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const DashboardPage(), const ScannerPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(
          Icons.logout_rounded,
          color: Colors.black45,
        ), // Visual only
        title: Image.asset('assets/Lexia.png', height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: "Scanner",
          ),
        ],
      ),
    );
  }
}
