import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';

class PublicTechnicianReviewsTab extends StatelessWidget {
  const PublicTechnicianReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/image/noReview.png", width: 230),
          const SizedBox(height: 20),
          const Text(
            "ยังไม่มีรีวิวในขณะนี้",
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
