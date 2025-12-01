import 'dart:io';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/activities/view_activity_by_id.dart';
import 'package:changsure/module/profile/technician/view_activities.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/button/tertiary_button.dart';
import '../../../../state/bottom_bar_state.dart';
import '../../../../state/ativity_state.dart';
import '../../../../models/technicians/technician_activity.dart';

class EditActivityById extends StatefulWidget {
  final int id;

  const EditActivityById({super.key, required this.id});

  @override
  State<EditActivityById> createState() => _EditActivityState();
}

class _EditActivityState extends State<EditActivityById> {
  String? selectedCategory;
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  List<String> existingImages = [];
  List<File> pickedImages = [];

  // error
  String? descriptionError;
  String? imageError;

  // เก็บค่าเดิม
  String? originalCategory;
  String? originalDescription;
  List<String> originalImages = [];

  bool get isChanged {
    return selectedCategory != originalCategory ||
        descriptionController.text != (originalDescription ?? "") ||
        pickedImages.isNotEmpty ||
        existingImages.length != originalImages.length;
  }

  bool get hasError => descriptionError != null || imageError != null;

  void _validateFields() {
    setState(() {
      descriptionError = descriptionController.text.trim().isEmpty
          ? "กรุณากรอกข้อมูลให้ครบถ้วน"
          : null;

      if (existingImages.isEmpty && pickedImages.isEmpty) {
        imageError = "กรุณาเพิ่มรูปภาพ";
      } else {
        imageError = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final state = context.read<TechnicianWorkState>();
      await state.loadWorkById(widget.id);

      final work = state.currentWork;
      if (work == null) return;

      // map ข้อมูลจาก API
      selectedCategory = work.serviceName;
      descriptionController.text = work.description ?? "";
      existingImages = work.images.map((e) => e.imageUrl).toList();

      // เก็บค่าเดิมไว้ตรวจว่าเปลี่ยนมั้ย
      originalCategory = selectedCategory;
      originalDescription = work.description;
      originalImages = List<String>.from(existingImages);

      _validateFields();
      setState(() {});
    });

    descriptionController.addListener(_validateFields);
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      pickedImages.add(File(file.path));
      _validateFields();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final workState = context.watch<TechnicianWorkState>();
    final work = workState.currentWork;

    // ------------------ Loading ------------------
    if (workState.isLoading || work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(
              header: "แก้ไขผลงาน",
              onPressed: () {
                context.read<BottomBarState>().setSubPage(
                  ViewActivityById(id: widget.id),
                );
              },
            ),
            const SizedBox(height: 16),

            // ------------------ Profile + Category ------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/image/Technician.png'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.serviceName ?? "ไม่ระบุหมวด",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------ TEXTAREA ------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: descriptionError != null
                            ? AppColors.colorError
                            : AppColors.colorStroke,
                      ),
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
                  if (descriptionError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        descriptionError!,
                        style: const TextStyle(
                          color: AppColors.colorError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------ IMAGE PICKER ------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // รูปเดิมจาก API
                      ...existingImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
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
                                  existingImages.removeAt(index);
                                  _validateFields();
                                  setState(() {});
                                },
                                child: _deleteIcon(),
                              ),
                            ),
                          ],
                        );
                      }),

                      // รูปใหม่ที่เลือก
                      ...pickedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
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
                                  pickedImages.removeAt(index);
                                  _validateFields();
                                  setState(() {});
                                },
                                child: _deleteIcon(),
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
                            border: Border.all(
                              color: imageError != null
                                  ? AppColors.colorError
                                  : AppColors.colorStroke,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: imageError != null
                                ? AppColors.colorError
                                : AppColors.primaryBorder,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (imageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        imageError!,
                        style: const TextStyle(
                          color: AppColors.colorError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------ SAVE BUTTON ------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  // ยกเลิก
                  Expanded(
                    child: TertiaryButton(
                      text: "ยกเลิก",
                      onPressed: () {
                        context.read<BottomBarState>().setSubPage(
                          ViewActivityById(id: widget.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // บันทึก
                  Expanded(
                    child: PrimaryButton(
                      text: "บันทึก",
                      onPressed: (!isChanged || hasError)
                          ? null
                          : () async {
                              // TODO: จุดนี้ upload รูปใหม่ก่อน
                              // final uploadedUrls = await uploadService.uploadFiles(pickedImages);

                              final dto = UpdateTechnicianWorkDTO(
                                description: descriptionController.text,
                                imageUrls: [
                                  ...existingImages,
                                  // ...uploadedUrls,
                                ],
                              );

                              final ok = await workState.updateWork(
                                work.id,
                                dto,
                              );

                              if (ok && mounted) {
                                context.read<BottomBarState>().setSubPage(
                                  ViewActivityById(id: widget.id),
                                );
                              }
                            },
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

  Widget _deleteIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.close, size: 14, color: Colors.white),
    );
  }
}
