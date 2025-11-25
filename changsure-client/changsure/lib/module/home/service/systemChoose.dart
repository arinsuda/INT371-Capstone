import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../mockDB/servicesCategories.dart';
import '../../profile/technician/viewProfile/service.dart';

class SystemChoose extends StatelessWidget {
  final String serviceName;

  const SystemChoose({super.key, required this.serviceName});

  Widget _buildTag(String imagePath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFFEDF9FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 16,
            height: 16,
          ),
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

  Widget buildSingleTag(String name) {
    final Map<String, Map<String, Color>> colorMap = {
      "ทาสี": {
        "text": Color(0xFFEB2F96),
        "background": Color(0xFFFFF0F6),
        "border": Color(0xFFFFADD2),
      },
      "การประปา": {
        "text": Color(0xFF36CFC9),
        "background": Color(0xFFE6FFFB),
        "border": Color(0xFF87E8DE),
      },
      "การไฟฟ้า": {
        "text": Color(0xFFFAAD14),
        "background": Color(0xFFFFFBE6),
        "border": Color(0xFFFFE58F),
      },
      "เครื่องใช้ไฟฟ้า": {
        "text": Color(0xFF722ED1),
        "background": Color(0xFFF9F0FF),
        "border": Color(0xFFD3ADF7),
      },
    };

    final colors = colorMap[name]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors["background"],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colors["border"]!,
          width: 1,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: colors["text"],
          fontSize: 12,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        children: [
          Header(header: "ระบบเลือกช่างอัตโนมัติ"),
          const SizedBox(height: 8),

          //Title
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0)
          ,child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black
                    ),
                  ),

                  const SizedBox(height: 4,),
                  const Text(
                    "เราจะแนะนำช่างที่เหมาะสมที่สุดตามงานของคุณ",
                    style: TextStyle(fontSize: 14, color: AppColors.colorTertiaryText),
                  ),
                ],
              ),),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBG,
                    border: Border.all(color: AppColors.colorStroke),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.colorTertiaryText),
                          SizedBox(width: 3),
                          Text(
                            "2 km",
                            style: TextStyle(
                                color: AppColors.colorTertiaryText, fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/image/Technician.png'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("คุณ",
                              style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Text("สมชาย รักชาติ",
                              style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Icon(Icons.verified, color: AppColors.primary, size: 12),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("฿",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Text("1,000",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star_rate_rounded,
                              color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text("4.9",
                              style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          Text(" / 5",
                              style: TextStyle(
                                  color: AppColors.colorTertiaryText, fontSize: 10)),
                          SizedBox(width: 4),
                          Text("|",
                              style:
                              TextStyle(color: AppColors.colorStroke, fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            "จำนวนงานที่รับ: 34",
                            style: TextStyle(
                                color: AppColors.colorTertiaryText, fontSize: 10),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// TAGS: Technician Badge
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTag("assets/icons/top_service.png", "Top Service"),
                          _buildTag(
                              "assets/icons/changSure_rec.png", "ChangSure Recommend"),
                          _buildTag("assets/icons/high_rating.png",
                              "High-Rating Technician"),
                          _buildTag("assets/icons/fast_response.png",
                              "Fast Response Technician"),
                        ],
                      ),

                      const SizedBox(height: 18),

                      /// ปุ่ม แต่ secondary button ยังไม่ได้แก้
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: "ดูโปรไฟล์",
                              onPressed: () {},
                            ),
                          ),
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

                // TAG มุมบนขวา
                Positioned(
                  top: 16,
                  right: 16,
                  child: buildSingleTag("ทาสี"),
                ),
              ],
            ),
          ),



        ],
      )),
    );
  }
}