import 'package:flutter/material.dart';

import '../../../../core/button/primary_button.dart';
import '../../../../core/theme.dart';


class TechnicianCardCTM extends StatelessWidget {

  const TechnicianCardCTM({super.key});

  Widget _buildTag(String imagePath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF9FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primaryBorderHover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String name) {
    final colorMap = {
      "ทาสี": {
        "text": const Color(0xFFEB2F96),
        "background": const Color(0xFFFFF0F6),
        "border": const Color(0xFFFFADD2),
      },
      "การประปา": {
        "text": const Color(0xFF36CFC9),
        "background": const Color(0xFFE6FFFB),
        "border": const Color(0xFF87E8DE),
      },
      "การไฟฟ้า": {
        "text": const Color(0xFFFAAD14),
        "background": const Color(0xFFFFFBE6),
        "border": const Color(0xFFFFE58F),
      },
      "เครื่องใช้ไฟฟ้า": {
        "text": const Color(0xFF722ED1),
        "background": const Color(0xFFF9F0FF),
        "border": const Color(0xFFD3ADF7),
      },
    };

    final color = colorMap[name] ?? colorMap["ทาสี"]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color["background"],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color["border"]!, width: 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color["text"],
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBG,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.colorStroke),
          ),
          child: Column(
            children: [
              // Row แรก Avatar + Technician info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Content
                  Column(
                    children: [
                      //Avatar
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/image/Technician.png'),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.colorTertiaryText),
                          SizedBox(width: 3),
                          Text("2 km",
                              style: TextStyle(
                                  color: AppColors.colorTertiaryText, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อ
                      Row(
                        children: const [
                          Flexible(child:
                          Text("คุณ",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold))),
                            SizedBox(width: 3),
                            Text("สมชาย รักชาติ",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.verified, color: AppColors.primary, size: 14),
                        ],
                      ),
                      SizedBox(height: 6,),

                      // price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Text("฿",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Text("1,000",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),

                      //rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Icon(Icons.star_rate_rounded,
                              color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text("4.9",
                              style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Text(" / 5",
                              style: TextStyle(
                                  color: AppColors.colorTertiaryText, fontSize: 10)),
                          SizedBox(width: 6),
                          Text("|",
                              style: TextStyle(
                                  color: AppColors.colorStroke, fontSize: 12)),
                          SizedBox(width: 6),
                          Text("จำนวนงานที่รับ: 34",
                              style: TextStyle(
                                  color: AppColors.colorTertiaryText, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Wrap(
                        spacing: 2,
                        runSpacing: 6,
                        alignment: WrapAlignment.start,
                        children: [
                          _buildTag("assets/icons/top_service.png", "Top Service"),
                          _buildTag(
                              "assets/icons/changSure_rec.png", "ChangSure Recommend"),
                          _buildTag(
                              "assets/icons/high_rating.png", "High-Rating Technician"),
                          _buildTag(
                              "assets/icons/fast_response.png",
                              "Fast Response Technician"),
                        ],
                      ),
                    ],
                  ))
                ],
              ),
              const SizedBox(height: 20),

              Row(
                // ปุ่ม
                  children: [
                    Expanded(
                        child:
                        PrimaryButton(text: "ดูโปรไฟล์", onPressed: () {})),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: "จองช่าง",
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // TAG หมวดหมู่มุมขวาบน
        Positioned(
          top: 16,
          right: 16,
          child: _buildCategoryTag("ทาสี"),
        ),
      ],
    );
  }
}
