import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/users/users_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/user_provider.dart';
import '../login_page.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  final String resetToken;

  const ChangePasswordPage({super.key, required this.resetToken});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isPasswordFormatValid(String password) {
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    return regex.hasMatch(password);
  }

  bool get _isPasswordValid {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    return password.isNotEmpty &&
        confirm.isNotEmpty &&
        password == confirm &&
        _isPasswordFormatValid(password);
  }

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(() {
      setState(() {});
    });

    _confirmPasswordController.addListener(() {
      setState(() {});
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggle,
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
          obscureText: obscureText,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "กรุณากรอกรหัสผ่าน";
            }

            final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

            if (!regex.hasMatch(value)) {
              return "รหัสผ่านต้องมีตัวอักษรและตัวเลข อย่างน้อย 8 ตัว";
            }

            return null;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
            errorStyle: const TextStyle(
              color: AppColors.colorError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.colorError,
                width: 1,
              ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: "รหัสผ่าน",
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      toggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    if (_passwordController.text.isNotEmpty &&
                        !_isPasswordFormatValid(_passwordController.text))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "รหัสผ่านต้องมีตัวอักษรภาษาอังกฤษ (A–Z) และตัวเลข (0–9) และมีความยาวอย่างน้อย 8 ตัวอักษร",
                          style: TextStyle(
                            color: AppColors.colorError,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(height: 24),

                    _buildTextField(
                      label: "ยืนยันรหัสผ่าน",
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      toggle: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    if (_confirmPasswordController.text.isNotEmpty &&
                        _passwordController.text !=
                            _confirmPasswordController.text)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "รหัสผ่านไม่ตรงกัน",
                          style: TextStyle(
                            color: AppColors.colorError,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: _isPasswordValid
                      ? () async {
                          final request = ResetPasswordRequest(
                            resetToken: widget.resetToken,
                            newPassword: _passwordController.text,
                            confirmPassword: _confirmPasswordController.text,
                          );

                          print(request);

                          final result = await ref.read(
                            resetPasswordProvider(request).future,
                          );

                          print(result.message);

                          ref.invalidate(userProvider);

                          Navigator.of(context).popUntil((route) => route.settings.name == "/login");
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
