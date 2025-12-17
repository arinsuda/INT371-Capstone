import 'package:changsure/data/models/users/users_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/state/user_provider.dart';
import 'package:changsure/data/services/auth_service.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const Color googleButtonColor = Colors.white;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: toLogicalPx(context, 24),
              vertical: toLogicalPx(context, 0),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'ลงชื่อเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 12)),
                    const Text(
                      'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 32)),

                    _buildTextField(
                      label: 'อีเมล',
                      controller: _usernameController,
                    ),
                    SizedBox(height: toLogicalPx(context, 16)),
                    _buildPasswordField(),
                    SizedBox(height: toLogicalPx(context, 16)),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Forgot Password ?',
                          style: TextStyle(
                            color: AppColors.primaryBorderHover,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 24)),

                    Align(
                      alignment: Alignment.centerRight,
                      child: PrimaryButton(
                        text: _isLoading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ',
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });

                                final authService = AuthService();

                                final Map<String, dynamic>? response =
                                    await authService.login(
                                      _usernameController.text.trim(),
                                      _passwordController.text.trim(),
                                    );

                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }

                                if (response != null &&
                                    response['data'] != null) {
                                  final Map<String, dynamic> data =
                                      response['data'];

                                  final accessToken = data['access_token'];
                                  final refreshToken = data['refresh_token'];

                                  Map<String, dynamic> decodedToken =
                                      JwtDecoder.decode(accessToken);

                                  UserRole role = UserRole.customer;
                                  if (decodedToken['role'] == 'technician') {
                                    role = UserRole.technician;
                                  }

                                  final userId =
                                      decodedToken['user_id'] ??
                                      decodedToken['sub'] ??
                                      0;

                                  final userModel = UserModel(
                                    id: userId,
                                    token: accessToken,
                                    role: role,
                                  );

                                  ref
                                      .read(userProvider.notifier)
                                      .login(userModel, refreshToken);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),

                    SizedBox(height: toLogicalPx(context, 24)),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            color: Color(0xFFE8E8E8),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'หรือ',
                            style: TextStyle(
                              color: AppColors.colorTertiaryText,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Color(0xFFE8E8E8),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: toLogicalPx(context, 16)),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(
                          color: AppColors.colorStroke,
                          width: 1,
                        ),
                        backgroundColor: googleButtonColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/image/Google_Logo.png',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'เข้าสู่ระบบด้วย Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 32)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ยังไม่มีบัญชีผู้ใช้?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.colorTertiaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'ลงทะเบียนเลย',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3071C7),
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
        },
      ),
    );
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
            fontSize: 12,
            color: AppColors.colorTertiaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3.5),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รหัสผ่าน',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.colorTertiaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3.5),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
