import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import '../../core/theme.dart';
import 'login_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
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
            padding: EdgeInsets.only(right: 24, left: 24 ,top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/image/Logo_ChangSure_Transparents.PNG", width: 300,),

                PrimaryButton(
                  text: 'เริ่มต้นใช้งาน',
                  onPressed: _onStartPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
