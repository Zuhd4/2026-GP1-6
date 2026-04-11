import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color textDark = Color(0xFF2D3142);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lexia',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFFCF8),
            textTheme: TextTheme(
              displayLarge: GoogleFonts.montserrat(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
              displayMedium: GoogleFonts.montserrat(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
              titleLarge: GoogleFonts.montserrat(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
              bodyLarge: GoogleFonts.montserrat(
                fontSize: 12.sp,
                color: textDark,
              ),
              bodyMedium: GoogleFonts.montserrat(
                fontSize: 11.sp,
                color: textDark,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
