import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// --- Data Model ---
class PostActivityState {
  final String? selectedCategory;
  final List<File> selectedImages;
  final String? descriptionError;
  final String? imageError;

  // ใช้สำหรับเช็คว่ามีการกรอกข้อมูลครบไหม (เพื่อเปิดปุ่ม Save)
  final bool isFormValid;

  const PostActivityState({
    this.selectedCategory,
    this.selectedImages = const [],
    this.descriptionError,
    this.imageError,
    this.isFormValid = false,
  });

  PostActivityState copyWith({
    String? selectedCategory,
    List<File>? selectedImages,
    String? descriptionError,
    String? imageError,
    bool? isFormValid,
  }) {
    return PostActivityState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedImages: selectedImages ?? this.selectedImages,
      descriptionError: descriptionError, // รับ null ได้เพื่อ clear error
      imageError: imageError, // รับ null ได้เพื่อ clear error
      isFormValid: isFormValid ?? this.isFormValid,
    );
  }
}

// --- Map สี (ใช้ร่วมกันได้ หรือจะแยกไฟล์ Constant ก็ดีครับ) ---
const Map<String, Map<String, Color>> kActivityColorMap = {
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

// --- Notifier ---
class PostActivityNotifier extends AutoDisposeNotifier<PostActivityState> {
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  PostActivityState build() {
    descriptionController.addListener(_validateForm);

    ref.onDispose(() {
      descriptionController.removeListener(_validateForm);
      descriptionController.dispose();
    });

    return const PostActivityState();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _validateForm();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final newImages = [...state.selectedImages, File(image.path)];
      state = state.copyWith(selectedImages: newImages);
      _validateForm();
    }
  }

  void removeImage(int index) {
    final newImages = [...state.selectedImages];
    newImages.removeAt(index);
    state = state.copyWith(selectedImages: newImages);
    _validateForm();
  }

  void _validateForm() {
    final bool hasCategory =
        state.selectedCategory != null && state.selectedCategory!.isNotEmpty;
    final bool hasDescription = descriptionController.text.trim().isNotEmpty;
    final bool hasImages = state.selectedImages.isNotEmpty;

    // Logic เดิมคือปุ่ม Save จะ Enable เมื่อกรอกครบทุกอย่าง
    state = state.copyWith(
      isFormValid: hasCategory && hasDescription && hasImages,
      // เราอาจจะยังไม่ show error แดงๆ ทันที จนกว่าจะกด Save หรือ submit
      // แต่ถ้าต้องการ show realtime ก็ใส่ logic เพิ่มตรงนี้ได้ครับ
    );
  }
}

// --- Provider ---
final postActivityProvider =
    NotifierProvider.autoDispose<PostActivityNotifier, PostActivityState>(
      PostActivityNotifier.new,
    );
