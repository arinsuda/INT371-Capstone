import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/button/tertiary_button.dart';
import '../../../../mockDB/activities.dart';
import '../../../../state/bottomBarState.dart';
import '../view_activities.dart';
import 'edit_activity_by_id.dart';

class ViewActivityById extends StatelessWidget {
  final int id;
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

  ViewActivityById({super.key, required this.id});

  void _showDeleteModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // พื้นหลังดำโปร่งแสง
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // หัวเรื่อง
                const Text(
                  "ลบผลงาน",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // ข้อความรายละเอียด
                const Text(
                  "คุณแน่ใจหรือไม่ว่าต้องการลบผลงานนี้ออกจากหน้าโปรไฟล์ช่างของคุณ? ผลงานดังกล่าวจะถูกลบออกจากโปรไฟล์ของคุณอย่างถาวร",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ปุ่มด้านล่าง
                Row(
                  children: [
                    // ปุ่มยกเลิก
                    Expanded(
                      child: TertiaryButton(
                        text: "ยกเลิก",
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.symmetric(vertical: 11),
                        fontSize: 14,
                        borderRadius: 8,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ปุ่มลบ
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF5222D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: const Color(0xFFF5222D),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // ทำการลบโพสต์จริง
                          Navigator.of(context).pop();
                          Provider.of<BottomBarState>(
                            context,
                            listen: false,
                          ).setSubPage(const ViewActivities());
                        },
                        child: const Text(
                          "ลบ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = mockActivities.firstWhere((a) => a.id == id);
    final categoryColor = colorMap[activity.serviceCategoryName];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                header: "ดูผลงาน",
                onPressed: () {
                  Provider.of<BottomBarState>(
                    context,
                    listen: false,
                  ).setSubPage(const ViewActivities());
                },
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: const AssetImage(
                        'assets/image/Technician.png',
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "คุณ สมชาย รักชาติ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),
                          //จะใส่ serviceCategoryName
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  categoryColor?["background"] ??
                                  Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: categoryColor?["border"] ?? Colors.grey,
                              ),
                            ),
                            child: Text(
                              activity.serviceCategoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: categoryColor?["text"] ?? Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          elevation: 4,
                          offset: const Offset(0, 40),
                          // ให้เมนูเลื่อนลงมาด้านล่างปุ่ม
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              // ทำอะไรเมื่อกดแก้ไขโพสต์
                              Provider.of<BottomBarState>(
                                context,
                                listen: false,
                              ).setSubPage(EditActivityById(id: activity.id));
                            } else if (value == 'delete') {
                              _showDeleteModal(context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: Icon(
                                        Icons.create_rounded,
                                        size: 20,
                                        color: AppColors.colorTertiaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text("แก้ไขโพสต์"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: AppColors.colorTertiaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text("ลบโพสต์"),
                                ],
                              ),
                            ),
                          ],
                          child: SvgPicture.asset(
                            'assets/icons/optionIcon.svg',
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                child: Text(
                  activity.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),

              // รูปภาพทั้งหมด
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...activity.images.map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(child: Image.asset(img)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
