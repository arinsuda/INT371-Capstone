import 'package:changsure/module/auth/login.dart';
import 'package:changsure/module/home/homePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/core/footer/footerBar.dart';
import 'package:provider/provider.dart';

import '../state/bottomBarState.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomBarState()),
      ],
      child: const MyApp(),
    ),
  );
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
      home: const LoginScreen(),
    );
  }
}
