import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/module/auth/password/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/user_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Image.asset("assets/image/ChangSure.png", height: 35),
                  ],
                ),

                SizedBox(height: 32),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "ลืมรหัสผ่านใช่หรือไม่?",
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "กรุณากรอกชื่ออีเมลที่ใช้งาน เพื่อรีเซ็ตรหัสผ่าน",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ),
                SizedBox(height: 32),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: _buildTextField(
                    label: "อีเมล",
                    controller: _emailController,
                  ),
                ),
                SizedBox(height: 24),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: PrimaryButton(
                    text: "ยืนยัน",
                    onPressed: () async {
                      print("BUTTON PRESSED");
                      if (!_formKey.currentState!.validate()) {
                        print("FORM INVALID");
                        return;
                      }

                      print("FORM VALID");

                      try {
                        print("CALL API");
                        final result = await ref.read(
                          requestOTPProvider(_emailController.text).future,
                        );
                        print("API DONE");
                        print("OTP: ${result.otp}");
                        print("Expire in: ${result.expiresIn}");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VerifyEmailPage(email: _emailController.text, expiredIn:result.expiresIn ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField({
  required String label,
  required TextEditingController controller,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.colorTertiaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 3.5),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) return 'รูปแบบอีเมลไม่ถูกต้อง';
          return null;
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          errorStyle: const TextStyle(
            color: AppColors.colorError,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.colorError, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.colorError,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primaryBorderHover,
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );
}
