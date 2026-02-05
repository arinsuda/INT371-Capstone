import 'package:flutter/material.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';

class ServiceSection extends StatelessWidget {
  const ServiceSection({super.key});

  bool get _isDirty => false;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "https://picsum.photos/100",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "บริการทำความสะอาดภายใน เกรดอัลตร้าพรีเมียม",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "฿400",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.calendar_month, color: AppColors.primary),
              SizedBox(width: 8),
              Text("7 ธันวาคม 2025, 9:00 - 12:00"),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Align(
        //   alignment: Alignment.centerRight,
        //   child: OutlinedButton(
        //     onPressed: () {},
        //     child: const Text("ดูรายละเอียดเพิ่มเติม"),
        //   ),
        // ),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 180,
            child: TertiaryButton(
              text: "ดูรายละเอียดเพิ่มเติม",
              onPressed: () {},
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: 20,
            ),
          ),
        ),
      ],
    );
  }
}
