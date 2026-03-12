import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // EXACT BACKGROUND COLOR FROM SCREENSHOT
        scaffoldBackgroundColor: const Color(0xFFF7F9FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFAC61FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
