import 'dart:io';
import 'package:changsure/core/button/primary_button.dart';
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

  // เก็บรูปที่เลือก
  final List<File> selectedImages = [];

  // Picker
  final ImagePicker picker = ImagePicker();

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

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImages.add(File(image.path));
      });
    }
  }

  bool _isPressed = false;
  bool _isCancelPressed = false;

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
                  bottom: MediaQuery.of(
                    context,
                  ).viewInsets.bottom, // ถ้ามี keyboard
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).setSubPage(const ViewActivities());
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "เพิ่มผลงาน",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AAD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
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
                child: const TextField(
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
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

                        // ปุ่มลบ
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImages.removeAt(index);
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

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Row(
                children: [
                  // ปุ่มยกเลิก
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() => _isCancelPressed = true);
                      },
                      onTapUp: (_) {
                        setState(() => _isCancelPressed = false);
                        Provider.of<BottomBarState>(
                          context,
                          listen: false,
                        ).setSubPage(const ViewActivities());
                      },
                      onTapCancel: () {
                        setState(() => _isCancelPressed = false);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isCancelPressed
                              ? AppColors.colorStroke
                              : AppColors.primaryBG,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: Center(
                          child: Text(
                            "ยกเลิก",
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ปุ่มบันทึก
                  Expanded(
                    child: PrimaryButton(
                      text: "บันทึก",
                      onPressed: () {
                        Provider.of<BottomBarState>(
                          context,
                          listen: false,
                        ).setSubPage(const ViewActivities());
                      },
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
