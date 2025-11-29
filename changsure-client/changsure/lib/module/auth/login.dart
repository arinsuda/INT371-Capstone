import 'package:changsure/core/footer/footer_bar.dart';
import 'package:flutter/material.dart';
import '../../core/button/primary_button.dart';
import '../../core/theme.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color googleButtonColor = Colors.white;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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

                    // ✅ ปุ่มเข้าสู่ระบบ
                    Align(
                      alignment: Alignment.centerRight,
                      child: PrimaryButton(
                        text: 'เข้าสู่ระบบ',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const FooterBarTemplate()),
                            );
                          }

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
