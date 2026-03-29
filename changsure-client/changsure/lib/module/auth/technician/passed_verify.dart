import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/header.dart';
import '../../../core/theme.dart';
import '../../../state/user_provider.dart';
import '../start_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class PassedVerify extends ConsumerStatefulWidget {
  const PassedVerify({super.key});

  @override
  ConsumerState<PassedVerify> createState() => _PassedVerifyState();
}

class _PassedVerifyState extends ConsumerState<PassedVerify> {
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
              child: Image.asset("assets/image/passed_verify.png", width: 400),
            ),

            const SizedBox(height: 32),

            const Center(
              child: Text(
                "สมัครเป็นช่างสำเร็จแล้ว",
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
                "ยินดีด้วย! ข้อมูลของคุณผ่านการตรวจสอบเรียบร้อยแล้ว "
                    "ตอนนี้คุณสามารถเริ่มรับงานจากลูกค้าใน ChangSure ได้ทันที ",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.primaryText),
              ),
            ),

            const SizedBox(height: 56),

            PrimaryButton(
              text: "กลับหน้าหลัก",
              onPressed: () {
                ref.read(userProvider.notifier).refreshUser();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const StartPage()),
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
