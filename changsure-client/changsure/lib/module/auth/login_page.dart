import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/module/auth/password/forgot_password_page.dart';
import 'package:changsure/module/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/state/user_provider.dart';
import 'package:changsure/data/services/auth_service.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  final _formKey = GlobalKey<FormState>();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '173461597544-cqjirm6jamgp745ak1tpc1t1b27shet7.apps.googleusercontent.com',
  );

  bool get _isFormValid {
    final email = _usernameController.text;
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return email.isNotEmpty &&
        password.isNotEmpty &&
        emailRegex.hasMatch(email);
  }

  Future<void> _handleLogin() async {
    print("LOGIN BUTTON PRESSED");
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final result = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      print("LOGIN RESULT: $result");

      if (result != null) {
        final roleStr = (result['role'] as String).toUpperCase();

        final user = UserModel(
          id: result['user_id'] as int,
          token: result['access_token'] as String,
          role: roleStr == 'TECHNICIAN'
              ? UserRole.technician
              : UserRole.customer,
        );

        final refreshToken = result['refresh_token'] as String;

        await ref.read(userProvider.notifier).login(user, refreshToken);
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        print("User cancelled login");
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      // TODO: ส่ง auth.idToken ไปยัง BE เพื่อแลก access_token
      print("ID Token: ${auth.idToken}");
      print("Access Token: ${auth.accessToken}");
      print("Email: ${account.email}");
    } catch (error) {
      print("Error signing in: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In ล้มเหลว: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 50),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        "assets/image/ChangSure.png",
                        height: 40,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ลงชื่อเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'กรุณากรอกอีเมลและรหัสผ่าน',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildTextField(
                      label: 'อีเมล',
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password ?',
                          style: TextStyle(
                            color: Color(0xFF3071C7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerRight,
                      child: PrimaryButton(
                        text: _isLoading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ',
                        onPressed: (!_isFormValid || _isLoading)
                            ? null
                            : _handleLogin,
                      ),
                    ),

                    // const SizedBox(height: 24),
                    // Row(
                    //   children: const [
                    //     Expanded(
                    //       child: Divider(
                    //         color: Color(0xFFE8E8E8),
                    //         thickness: 1,
                    //       ),
                    //     ),
                    //     Padding(
                    //       padding: EdgeInsets.symmetric(horizontal: 10),
                    //       child: Text(
                    //         'หรือ',
                    //         style: TextStyle(
                    //           color: AppColors.colorTertiaryText,
                    //         ),
                    //       ),
                    //     ),
                    //     Expanded(
                    //       child: Divider(
                    //         color: Color(0xFFE8E8E8),
                    //         thickness: 1,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),
                    // OutlinedButton(
                    //   onPressed: _signInWithGoogle,
                    //   style: OutlinedButton.styleFrom(
                    //     minimumSize: const Size(double.infinity, 48),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     side: const BorderSide(
                    //       color: AppColors.colorStroke,
                    //       width: 1,
                    //     ),
                    //     backgroundColor: googleButtonColor,
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Image.asset(
                    //         'assets/image/Google_Logo.png',
                    //         width: 18,
                    //         height: 18,
                    //       ),
                    //       const SizedBox(width: 10),
                    //       const Text(
                    //         'เข้าสู่ระบบด้วย Google',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w500,
                    //           color: Colors.black,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 32),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
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
          ],
        ),
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
            fontSize: 14,
            color: AppColors.colorTertiaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3.5),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
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
            fontSize: 14,
            color: AppColors.colorTertiaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3.5),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
            return null;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
}
