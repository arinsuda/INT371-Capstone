import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import '../../core/theme.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onStartPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(toLogicalPx(context, 24)),
            child: PrimaryButton(
              text: 'เริ่มต้นใช้งาน',
              onPressed: _onStartPressed,
            ),
          ),
        ),
      ),
    );
  }
}

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
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // จัดตรงกลางแนวตั้ง
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // ------------------- เริ่ม login form -------------------
                    Text(
                      'ลงชื่อเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 12)),
                    Text(
                      'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 32)),
                    Text(
                      'ชื่อผู้ใช้',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.colorTertiaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 3.5)),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: AppColors.colorStroke,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: AppColors.primaryBorderHover,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: toLogicalPx(context, 12.5),
                          horizontal: toLogicalPx(context, 16),
                        ),
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 16)),
                    Text(
                      'รหัสผ่าน',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.colorTertiaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: toLogicalPx(context, 3.5)),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: AppColors.primaryBorder,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: AppColors.primaryBorderHover,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: toLogicalPx(context, 16),
                          horizontal: toLogicalPx(context, 12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
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
                    SizedBox(height: toLogicalPx(context, 16)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
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
                      child:
                      PrimaryButton(text: 'เข้าสู่ระบบ', onPressed: () {}),
                    ),
                    SizedBox(height: toLogicalPx(context, 24)),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child:
                          Divider(color: Color(0xFFE8E8E8), thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: toLogicalPx(context, 10),
                          ),
                          child: const Text(
                            'หรือ',
                            style:
                            TextStyle(color: AppColors.colorTertiaryText),
                          ),
                        ),
                        const Expanded(
                          child:
                          Divider(color: Color(0xFFE8E8E8), thickness: 1),
                        ),
                      ],
                    ),
                    SizedBox(height: toLogicalPx(context, 16)),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(
                            color: AppColors.colorStroke, width: 1),
                        backgroundColor: googleButtonColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            'assets/image/Google_Logo.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 10),
                          Text(
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
                        Text(
                          'ยังไม่มีบัญชีผู้ใช้?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.colorTertiaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
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
}
