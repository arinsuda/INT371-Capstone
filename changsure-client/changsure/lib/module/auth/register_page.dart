import 'package:changsure/module/auth/choose_role_page.dart';
import 'package:changsure/module/auth/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/button/primary_button.dart';
import '../../core/theme.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  static const Color googleButtonColor = Colors.white;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _checkPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '173461597544-cqjirm6jamgp745ak1tpc1t1b27shet7.apps.googleusercontent.com',
  );

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        print("User cancelled login");
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      print("ID Token: ${auth.idToken}");
      print("Access Token: ${auth.accessToken}");
      print("Email: ${account.email}");
      print("Name: ${account.displayName}");
    } catch (error) {
      print("Error signing in: $error");
    }
  }

  bool get _isFormValid {
    return _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _checkPasswordController.text.isNotEmpty &&
        _passwordController.text == _checkPasswordController.text &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_usernameController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 100),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
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
                      SizedBox(height: 32),

                      const Text(
                        'ลงทะเบียน',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 24),
                      const Text(
                        'สร้างบัญชีผู้ใช้',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                      SizedBox(height: 32),

                      _buildTextField(
                        label: 'อีเมล',
                        controller: _usernameController,
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'รหัสผ่าน',
                        controller: _passwordController,
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'ยืนยันรหัสผ่าน',
                        controller: _checkPasswordController,
                        isConfirm: true,
                      ),

                      SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerRight,
                        child: PrimaryButton(
                          text: 'ลงทะเบียน',
                          onPressed: (!_isFormValid)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) => ChooseRolePage(
                                        email: _usernameController.text.trim(),
                                        password: _passwordController.text
                                            .trim(),
                                        confirmPassword:
                                            _checkPasswordController.text
                                                .trim(),
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),

                      SizedBox(height: 24),
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
                      SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: signInWithGoogle,
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
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'มีบัญชีผู้ใช้อยุู่แล้ว?',
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
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'เข้าสู่ระบบ',
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
          // 👈 trigger rebuild
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกอีเมล';
            }

            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

            if (!emailRegex.hasMatch(value)) {
              return 'รูปแบบอีเมลไม่ถูกต้อง';
            }

            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            // 🔴 สีข้อความ error
            errorStyle: const TextStyle(
              color: AppColors.colorError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),

            // 🔴 สีกรอบตอน error
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.colorError,
                width: 1,
              ),
            ),

            // 🔴 สีกรอบตอน focus + error
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    bool isConfirm = false,
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
          obscureText: _obscurePassword,
          onChanged: (_) {
            if (isConfirm) {
              _formKey.currentState?.validate();
            }
            setState(() {});
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกรหัสผ่าน';
            }

            if (isConfirm && value != _passwordController.text) {
              return 'กรุณากรอกรหัสผ่านให้ถูกต้อง';
            }

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
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            // 🔴 สีข้อความ error
            errorStyle: const TextStyle(
              color: AppColors.colorError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),

            // 🔴 สีกรอบตอน error
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.colorError,
                width: 1,
              ),
            ),

            // 🔴 สีกรอบตอน focus + error
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
}
