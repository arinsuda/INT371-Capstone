import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:changsure/core/theme.dart'; // ✅ ใช้ theme
import 'package:changsure/core/button/primary_button.dart'; // ✅ ใช้ปุ่มที่แยก component

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

        // 👇 เพิ่มส่วนนี้เพื่อกำหนดฟอนต์ทั้งแอป
        textTheme: GoogleFonts.notoSansThaiTextTheme(),

        // ถ้าคุณอยากให้ AppBar และปุ่มใช้ฟอนต์เดียวกัน
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.notoSansThai(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StateFullWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              text: 'เริ่มต้นใช้งาน',
              onPressed: () {
                // เมื่อกดปุ่ม
              },
            ),
          ),
        ),
      ),
    );
  }
}
