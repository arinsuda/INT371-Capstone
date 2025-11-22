import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import '../../core/theme.dart';
import '../auth/login.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onStartPressed() {
    final authRepo = Provider.of<AuthRepository>(context, listen: false);

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
