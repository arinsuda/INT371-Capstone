import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme.dart';
import '../../../mockDB/servicesCategories.dart';

class ServiceTag extends StatelessWidget {
  const ServiceTag({super.key});

  @override
  Widget build(BuildContext context) {
    // สีตามหมวดบริการ
    final Map<String, Map<String, Color>> colorMap = {
      "ช่างทาสี": {
        "text": const Color(0xFFEB2F96),
        "background": const Color(0xFFFFF0F6),
        "border": const Color(0xFFFFADD2),
      },
      "ช่างประปา": {
        "text": const Color(0xFF36CFC9),
        "background": const Color(0xFFE6FFFB),
        "border": const Color(0xFF87E8DE),
      },
      "ช่างไฟฟ้า": {
        "text": const Color(0xFFFAAD14),
        "background": const Color(0xFFFFFBE6),
        "border": const Color(0xFFFFE58F),
      },
      "ช่างซ่อมเครื่องใช้ไฟฟ้า": {
        "text": const Color(0xFF722ED1),
        "background": const Color(0xFFF9F0FF),
        "border": const Color(0xFFD3ADF7),
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ประเภทงานที่รับบริการ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mockServiceCategories.map((category) {
            final colors = colorMap[category.name]!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors["background"],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colors["border"]!,
                  width: 1,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: colors["text"],
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}