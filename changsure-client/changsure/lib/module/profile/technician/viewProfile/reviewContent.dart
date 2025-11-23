import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class ReviewContent extends StatelessWidget {
  const ReviewContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "รีวิวช่าง",
        style: TextStyle(fontSize: 16, color: AppColors.primary),
      ),
    );
  }
}
