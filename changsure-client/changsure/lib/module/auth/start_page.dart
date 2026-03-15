import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/footer/footer_bar.dart';
import '../../state/user_provider.dart';
import '../home/home_page.dart'; // 👈 import หน้า Home ของคุณ
import 'login_page.dart';
import '../../core/button/primary_button.dart';

class StartPage extends ConsumerWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    // ✅ ถ้า login แล้ว → ไปหน้า Home ทันที
    if (user != null && user.isAuthenticated) {
      return const FooterBarTemplate();
    }

    // ❌ ถ้ายังไม่ login → แสดงหน้าเริ่มต้น
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/image/Logo_ChangSure_Transparents.PNG",
                  width: 300,
                ),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: 'เริ่มต้นใช้งาน',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: "/login"),
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}