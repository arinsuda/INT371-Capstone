import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../module/profile/technician/activities/view_activity_by_id.dart';
import '../../state/bottomBarState.dart';
import '../theme.dart';

class TechnicianCard extends StatelessWidget {
  final int id;
  final String serviceCategoryName;
  final String description;
  final List<String> images;

  const TechnicianCard({
    super.key,
    required this.id,
    required this.serviceCategoryName,
    required this.description,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
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

    final categoryColors =
        colorMap[serviceCategoryName] ??
        {
          "text": Colors.purple,
          "background": Colors.purple.shade100,
          "border": Colors.purple.shade300,
        };

    Widget buildImages() {
      if (images.length == 1) {
        // รูปเดียว แสดงเต็ม
        return Image.asset(
          images[0],
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        // 2 รูปขึ้นไป
        int extraCount = images.length - 3;
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                ),
                child: Image.asset(
                  images[0],
                  height: 120, // ความสูงคงที่
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 120, // ทำให้เท่ากับรูปใหญ่ด้านซ้าย
                child: Column(
                  children: List.generate(
                    images.length - 1 > 2 ? 2 : images.length - 1,
                    (index) {
                      bool isLastWithExtra = index == 1 && extraCount > 0;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: index == 0 ? 4.0 : 0,
                          ),
                          child: Stack(
                            children: [
                              Image.asset(
                                images[index + 1],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              if (isLastWithExtra)
                                Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Center(
                                    child: Text(
                                      '+$extraCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    return GestureDetector(
      onTap: () {
        Provider.of<BottomBarState>(
          context,
          listen: false,
        ).setSubPage(ViewActivityById(id: id));
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stack สำหรับรูป + label
            Stack(
              children: [
                // รูปภาพ ชิดขอบบน + top corners โค้ง
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: buildImages(),
                ),
                // Label serviceCategory ซ้อนบนซ้าย
                Positioned(
                  top: 0,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColors["background"],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        bottomLeft: Radius.circular(10),
                        topRight: Radius.circular(0),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      serviceCategoryName,
                      style: TextStyle(
                        color: categoryColors["text"],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Description (บังคับ 2 บรรทัด)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 35,
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ดูรายละเอียดเพิ่มเติม
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "ดูรายละเอียดเพิ่มเติม",
                style: TextStyle(
                  color: AppColors.primaryBorderHover,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ), // UI การ์ดเดิม
    );
  }
}
