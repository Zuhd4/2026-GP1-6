import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // This imports your new file

void main() {
  // Keep your Firebase init here if you're using it later
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lexia',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // Set the LoginScreen as the first thing the user sees
      home: const LoginScreen(),
    );
  }
}
