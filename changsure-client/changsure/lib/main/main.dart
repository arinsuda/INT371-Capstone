import 'package:changsure/module/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import '../core/footer/footer_bar.dart';
import '../state/bottom_bar_state.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('th_TH', null);
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
        scaffoldBackgroundColor: Colors.white,
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
      home: const AppRoot(),
    );
  }
}

/// Root widget ของแอป ใช้ BottomBar อยู่ตลอด
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = true; // ปรับ logic ตรวจสอบ login จริงได้

    // ถ้ายังไม่ login → แสดงหน้า Login
    if (!isLoggedIn) {
      return const LoginScreen();
    }

    // ถ้า login แล้ว → ใช้ FooterBarTemplate ที่มี BottomBar
    return const FooterBarTemplate();
  }
}