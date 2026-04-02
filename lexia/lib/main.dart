import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Define a dark text color to ensure visibility
        const Color textDark = Color(0xFF2D3142);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lexia',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color.fromARGB(255, 249, 247, 248),

            // We define the sizes MANUALLY here.
            // This prevents the "fontSize != null" error 100%.
            textTheme: TextTheme(
              // Large Headers (Hello Parent, Books)
              displayLarge: GoogleFonts.montserrat(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
              displayMedium: GoogleFonts.montserrat(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),

              // Card Titles (Child names)
              titleLarge: GoogleFonts.montserrat(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
              titleMedium: GoogleFonts.montserrat(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),

              // Body text (Descriptions, status)
              bodyLarge: GoogleFonts.montserrat(
                fontSize: 12.sp,
                color: textDark,
              ),
              bodyMedium: GoogleFonts.montserrat(
                fontSize: 10.sp,
                color: textDark,
              ),

              // Smallest labels (Profile, Level)
              labelSmall: GoogleFonts.montserrat(
                fontSize: 7.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black38,
              ),
            ),
          ),
          home: child,
        );
      },
      child: const Wrapper(),
    );
  }
}
