import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme.dart';

class TechnicianBadge extends StatelessWidget {
  const TechnicianBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {
        'label': 'Top Service Technician',
        'icon': 'assets/icons/top_service.png',
      },
      {
        'label': 'ChangSure Recommend',
        'icon': 'assets/icons/changSure_rec.',
      },
      {
        'label': 'High-Rating Technician',
        'icon': 'assets/icons/high_rating.png',
      },
      {
        'label': 'Fast Response Technician',
        'icon': 'assets/icons/fast_response.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- หัวข้อ Section ----------
        Padding(
          padding: const EdgeInsets.only(bottom: 0, left: 4, top: 24),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/badge.svg',
                    width: 14,
                    height: 14,
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Text(
                'ป้ายสัญลักษณ์ของช่าง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // ---------- ป้าย Badge ----------
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: buttons.map((button) {
              final iconPath = button['icon'] as String;

              return Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Center(
                          child: Image.asset(
                            iconPath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          button['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
