import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/button/primaryButton.dart';
import '../../repositories/auth_repository.dart';

import 'login.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  void _onStartPressed() {
    final authRepo = context.read<AuthRepository>();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(authRepo: authRepo)),
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
