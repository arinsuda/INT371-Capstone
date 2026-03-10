import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _passwordController = TextEditingController();
  final  _confirmPasswordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 6, vertical: 32),
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
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: Text(
                  "เปลี่ยนรหัสผ่าน",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: Text(
                  "กรุณากรอกรหัสผ่านใหม่",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),
              SizedBox(height: 32),

              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: Column(children: [
                  _buildTextField(
                    label: "รหัสผ่าน",
                    controller: _passwordController,
                  ),
                  SizedBox(height: 24),

                  _buildTextField(
                    label: "ยืนยันรหัสผ่าน",
                    controller: _confirmPasswordController,
                  ),
                ],)
              ),
              SizedBox(height: 24),

              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: PrimaryButton(text: "ยืนยัน", onPressed: () {}),
              ),
            ],
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
