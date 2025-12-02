import 'dart:io';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/activities/view_activity_by_id.dart';
import 'package:changsure/module/profile/technician/activities/view_activity_by_id.dart';
import 'package:changsure/module/profile/technician/view_activities.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/button/tertiary_button.dart';
import '../../../../mockDB/activities.dart';
import '../../../../state/bottom_bar_state.dart';

class EditActivityById extends StatefulWidget {
  final int id; // รับไอดีมาด้วย

  const EditActivityById({super.key, required this.id});

  @override
  State<EditActivityById> createState() => _EditActivityState();
}

class _EditActivityState extends State<EditActivityById> {
  String? selectedCategory;
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  // รูป default จาก activity
  List<String> assetImages = [];

  // รูปใหม่จาก gallery
  List<File> pickedImages = [];

  // สีตามหมวด
  final Map<String, Map<String, Color>> colorMap = {
    "ช่างทาสี": {
      "text": Color(0xFFEB2F96),
      "background": Color(0xFFFFF0F6),
      "border": Color(0xFFFFADD2),
    },
    "ช่างประปา": {
      "text": Color(0xFF36CFC9),
      "background": Color(0xFFE6FFFB),
      "border": Color(0xFF87E8DE),
    },
    "ช่างไฟฟ้า": {
      "text": Color(0xFFFAAD14),
      "background": Color(0xFFFFFBE6),
      "border": Color(0xFFFFE58F),
    },
    "ช่างซ่อมเครื่องใช้ไฟฟ้า": {
      "text": Color(0xFF722ED1),
      "background": Color(0xFFF9F0FF),
      "border": Color(0xFFD3ADF7),
    },
  };

  // Original data สำหรับเช็คว่ามีการแก้ไขหรือไม่
  String? originalCategory;
  String? originalDescription;
  List<String> originalImages = [];

  bool get isChanged {
    return selectedCategory != originalCategory ||
        descriptionController.text != (originalDescription ?? '') ||
        pickedImages.isNotEmpty ||
        assetImages.length != originalImages.length;
  }

  @override
  void initState() {
    super.initState();
    final activity = mockActivities.firstWhere((a) => a.id == widget.id);

    selectedCategory = activity.serviceCategoryName;
    descriptionController.text = activity.description;
    assetImages = List<String>.from(activity.images);

    originalCategory = selectedCategory;
    originalDescription = activity.description;
    originalImages = List<String>.from(activity.images);

    descriptionController.addListener(() {
      setState(() {}); // เพื่อให้ isChanged ประเมินใหม่
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        pickedImages.add(File(image.path));
      });
    }
  }

  Widget buildCategoryDropdown() {
    final colors = selectedCategory != null ? colorMap[selectedCategory] : null;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: colorMap.keys.map((categoryName) {
                    final itemColor = colorMap[categoryName] ?? {};
                    return ListTile(
                      title: Text(
                        categoryName,
                        style: TextStyle(
                          color: itemColor["text"] ?? Colors.black,
                        ),
                      ),
                      onTap: () {
                        setState(() => selectedCategory = categoryName);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors?["background"] ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: colors?["border"] ?? Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCategory ?? "เลือกหมวด",
              style: TextStyle(
                color: colors?["text"] ?? Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: colors?["text"] ?? Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            // ---------- Header ----------
            Header(
              header: "แก้ไขผลงาน",
              onPressed: () {
                Provider.of<BottomBarState>(
                  context,
                  listen: false,
                ).setSubPage(ViewActivityById(id: widget.id));
              },
            ),

            const SizedBox(height: 16),

            // ---------- Profile Section ----------
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
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
                        buildCategoryDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- TEXTAREA ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.colorStroke),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "กรอกคำอธิบายผลงาน...",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- IMAGE UPLOAD ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // รูปจาก activity (asset)
                  ...assetImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            path,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                assetImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // รูปจาก gallery
                  ...pickedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final img = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            img,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                pickedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // ปุ่มเพิ่มรูป
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.colorStroke),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryBorder,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
              child:
              Row(
                children: [
                  // ปุ่มยกเลิก
                  Expanded(
                    child: TertiaryButton(
                      text: "ยกเลิก",
                      onPressed: () {
                        Provider.of<BottomBarState>(
                          context,
                          listen: false,
                        ).setSubPage(ViewActivityById(id: widget.id));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ปุ่มบันทึก
                  Expanded(
                    child: PrimaryButton(
                      text: "บันทึก",
                      onPressed: isChanged
                          ? () {
                              // ทำการบันทึก
                              Provider.of<BottomBarState>(
                                context,
                                listen: false,
                              ).setSubPage(ViewActivityById(id: widget.id));
                            }
                          : null, // disabled ถ้าไม่มีการแก้ไข
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
