import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/image/noPayment.png", width: 300),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่มีงานที่รอชำระเงิน',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
