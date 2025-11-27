import 'dart:io';
import 'package:changsure/core/button/primaryButton.dart';
import 'package:changsure/core/button/tertiaryButton.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/viewActivities.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../state/bottomBarState.dart';

class PostActivity extends StatefulWidget {
  const PostActivity({super.key});

  @override
  State<PostActivity> createState() => _PostActivityState();
}

class _PostActivityState extends State<PostActivity> {
  // ค่า Dropdown
  String? selectedCategory;
  String? initialCategory;

  // เก็บรูปที่เลือก
  final List<File> selectedImages = [];
  List<File> initialImages = [];

  // Picker
  final ImagePicker picker = ImagePicker();

  // Text controller สำหรับคำอธิบาย
  final TextEditingController descriptionController = TextEditingController();

  bool hasChanged = false;
  bool _isPressed = false;
  bool _isCancelPressed = false;

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

  @override
  void initState() {
    super.initState();

    // listener สำหรับ TextField
    descriptionController.addListener(_checkChanged);

    // เก็บค่าเริ่มต้น (ตอนเปิดหน้าครั้งแรก)
    initialCategory = selectedCategory;
    initialImages = List<File>.from(selectedImages);
  }

  void _checkChanged() {
    bool changed = false;

    // 1. ตรวจ Dropdown
    changed |= (selectedCategory != null && selectedCategory!.isNotEmpty);

    // 2. ตรวจ TextField
    changed |= (descriptionController.text.isNotEmpty);

    // 3. ตรวจรูปภาพ
    changed |= (selectedImages.isNotEmpty);

    bool allFilled =
        (selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedImages.isNotEmpty);

    if (hasChanged != allFilled) {
      setState(() {
        hasChanged = allFilled;
      });
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImages.add(File(image.path));
        _checkChanged();
      });
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
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
                        _checkChanged();
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
              header: "เพิ่มผลงาน",
              onPressed: () {
                Provider.of<BottomBarState>(
                  context,
                  listen: false,
                ).setSubPage(const ViewActivities());
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
                  ...selectedImages.asMap().entries.map((entry) {
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
                                selectedImages.removeAt(index);
                                _checkChanged();
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
                  }).toList(),
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
            const SizedBox(height: 20),

            // ---------------- BUTTONS ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Row(
                children: [
                  // ปุ่มยกเลิก
                  Expanded(
                    child: TertiaryButton(
                      text: "ยกเลิก",
                      onPressed: () {
                        Provider.of<BottomBarState>(
                          context,
                          listen: false,
                        ).setSubPage(const ViewActivities());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ปุ่มบันทึก
                  Expanded(
                    child: PrimaryButton(
                      text: "บันทึก",
                      onPressed: hasChanged
                          ? () {
                              Provider.of<BottomBarState>(
                                context,
                                listen: false,
                              ).setSubPage(const ViewActivities());
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
