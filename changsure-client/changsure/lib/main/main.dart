import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:changsure/core/theme.dart';


import '../module/auth/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Changsure App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansThaiTextTheme(),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.notoSansThai(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

