import 'package:changsure/core/footer/footer_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/button/primary_button.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

import '../../models/auth/login_request.dart';
import '../../state/auth_state.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class LoginScreen extends StatefulWidget {
  final AuthService authRepo;

  const LoginScreen({super.key, required this.authRepo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color googleButtonColor = Colors.white;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกชื่อผู้ใช้และรหัสผ่าน")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final req = LoginRequest(email: email, password: password);

      final res = await widget.authRepo.login(req);

      final authState = Provider.of<AuthState>(context, listen: false);
      await authState.setToken(res.accessToken);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FooterBarTemplate()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เข้าสู่ระบบล้มเหลว: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                      label: 'ชื่อผู้ใช้',
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
                        text: _loading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
                        onPressed: () => _onLoginPressed(),
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
