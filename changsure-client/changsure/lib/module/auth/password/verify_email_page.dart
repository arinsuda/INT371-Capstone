import 'dart:async';

import 'package:changsure/module/auth/password/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/users/users_model.dart';
import '../../../state/user_provider.dart';
import 'widget/otp_input_widget.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String email;
  final int expiredIn;

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.expiredIn,
  });

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  String _otp = "";
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _remainingSeconds = widget.expiredIn;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

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
                child: OtpInputWidget(
                  onCompleted: (otp) {
                    setState(() {
                      _otp = otp;
                    });
                  },
                ),
              ),

              SizedBox(height: 32),

              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: () async {
                    print(_otp);

                    final request = VerifyOTPRequest(
                      email: widget.email,
                      otp: _otp,
                    );

                    final result = await ref.read(
                      verifyOTPProvider(request).future,
                    );

                    print(result.resetToken);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangePasswordPage(resetToken: result.resetToken),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),

              Center(
                child: Text(
                  "รหัสนี้จะหมดอายุใน $formattedTime นาที",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),

              SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "ยังไม่ได้รับรหัสใช่หรือไม่?",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(width: 4),

                  GestureDetector(
                    onTap: () async {
                      try {
                        ref.invalidate(requestOTPProvider(widget.email));

                        final result = await ref.read(
                          requestOTPProvider(widget.email).future,
                        );

                        print("OTP ${result.otp}");

                        setState(() {
                          _remainingSeconds = result.expiresIn;
                        });

                        _timer?.cancel();

                        _timer = Timer.periodic(const Duration(seconds: 1), (
                          timer,
                        ) {
                          if (_remainingSeconds <= 0) {
                            timer.cancel();
                          } else {
                            setState(() {
                              _remainingSeconds--;
                            });
                          }
                        });
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text(
                      "ส่งอีกครั้ง",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
