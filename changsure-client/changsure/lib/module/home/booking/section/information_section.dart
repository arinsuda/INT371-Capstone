import 'dart:io';

import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InformationCard extends StatefulWidget {
  final void Function(String? note, List<File> images)? onChanged;
  const InformationCard({super.key, this.onChanged});

  @override
  State<InformationCard> createState() => _InformationCardState();
}

class _InformationCardState extends State<InformationCard> {
  final ImagePicker picker = ImagePicker();
  final List<File> selectedImages = [];
  late TextEditingController infoController;

  @override
  void initState() {
    super.initState();
    infoController = TextEditingController();

    infoController.addListener(() {
      setState(() {});
      _checkChanged();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkChanged();
    });

  }

  @override
  void dispose() {
    infoController.dispose();
    super.dispose();
  }

  void _checkChanged() {
    widget.onChanged?.call(
      infoController.text.isEmpty ? null : infoController.text,
      selectedImages,
    );
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        selectedImages.add(File(image.path));
        _checkChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ข้อมูลเพิ่มเติม (ไม่บังคับ)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),

          const Text("รูปภาพหน้างาน", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),

          Wrap(
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
                      top: 4,
                      right: 4,
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
              }),

              /// ปุ่มเพิ่มรูป
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

          const SizedBox(height: 16),

          _buildTextArea(
            label: "รายละเอียดเพิ่มเติม",
            controller: infoController,
          ),
        ],
      ),
    );
  }
}

Widget _buildTextArea({
  required String label,
  required TextEditingController controller,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: 500,
          maxLines: 5,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'เขียนรายละเอียดเพิ่มเติม...',
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBorder,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        /// Footer ใต้กล่อง
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'กรอกรายละเอียดเพื่อให้ช่างเข้าใจปัญหาของคุณ เพื่อการทำงานที่มีประสิทธิภาพมากขึ้น',
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ),
            SizedBox(width: 24),
            Text(
              '${controller.text.length}/500',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.colorTertiaryText,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
