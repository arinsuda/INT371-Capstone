import 'package:flutter/material.dart';

class SuccessView extends StatelessWidget {
  final double amount;

  const SuccessView({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          const Text(
            'ชำระเงินเสร็จสิ้น',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Text(
            '฿${amount.toInt()}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),

          Image.asset(
            'assets/image/noPayment.png',
            height: 200,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.account_balance_wallet_outlined,
              size: 150,
              color: Color(0xFF003DAB),
            ),
          ),
          const SizedBox(height: 40),

          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'กลับหน้าติดตามสถานะ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
