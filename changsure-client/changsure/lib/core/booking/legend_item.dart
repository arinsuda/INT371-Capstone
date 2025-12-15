import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.colorTertiaryText,
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }
}
