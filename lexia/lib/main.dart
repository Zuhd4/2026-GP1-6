import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'wrapper.dart';

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
      title: 'Lexia',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 249, 247, 248),
        useMaterial3: true,
      ),

      home: const Wrapper(),
    );
  }
}
