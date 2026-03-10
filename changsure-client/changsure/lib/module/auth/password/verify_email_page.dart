import 'package:changsure/module/auth/password/change_password_page.dart';
import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import 'otp_input_widget.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  String _otp = "";
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
                  "ตรวจสอบยืนยันอีเมล",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: Text(
                  "กรุณาป้อนรหัสที่ส่งไปยัง ${widget.email}",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),
              SizedBox(height: 32),

              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: OtpInputWidget(),
              ),

              SizedBox(height: 32),

              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: () {
                    print("OTP: $_otp");
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ChangePasswordPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
