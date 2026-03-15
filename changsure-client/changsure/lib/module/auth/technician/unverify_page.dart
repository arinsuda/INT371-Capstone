import 'package:changsure/module/auth/login_page.dart';
import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/header.dart';
import '../../../core/theme.dart';

class UnverifyPage extends StatelessWidget {
  const UnverifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12, vertical: 16),
          children: [
            Header(
              header: "ลงทะเบียนช่าง",
              fontSize: 26,
              color: AppColors.primaryText,
            ),
            const SizedBox(height: 32),

            Center(
              child: Image.asset("assets/image/unverify.png", width: 300),
            ),

            const SizedBox(height: 32),

            const Center(
              child: Text(
                "ไม่สามารถอนุมัติการสมัครได้",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "ขออภัย ขณะนี้ระบบไม่สามารถอนุมัติการสมัครเป็นช่างใน "
                "ChangSure ได้เนื่องจากผลการตรวจสอบข้อมูลไม่เป็น "
                "ไปตามเงื่อนไขความปลอดภัยของแพลตฟอร์ม",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.primaryText),
              ),
            ),

            const SizedBox(height: 56),

            const Center(
              child: Text(
                "หากต้องการสอบถามข้อมูลเพิ่มเติม สามารถติดต่อทีมงานได้ที่ "
                "sit.changsure@gmail.com",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF737373)),
              ),
            ),
            const SizedBox(height: 32),


            PrimaryButton(
              text: "กลับหน้าเข้าสู่ระบบ",
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
              padding: EdgeInsetsGeometry.symmetric(vertical: 8),
            ),
          ],
        ),
      ),
    );
  }
}
