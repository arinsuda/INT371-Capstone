import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:changsure/mockDB/activities.dart';

// --- Data Model (Immutable State) ---
class ActivityEditorState {
  final String? selectedCategory;
  final List<String> assetImages;
  final List<File> pickedImages;
  final String? descriptionError;
  final String? imageError;

  // เก็บค่าเดิมไว้เช็คว่ามีการแก้ไขหรือไม่ (isChanged)
  final String? originalCategory;
  final String? originalDescription;
  final List<String> originalImages;

  // เก็บ text ปัจจุบันเพื่อเทียบกับ original (แยกจาก Controller)
  final String currentDescription;

  const ActivityEditorState({
    this.selectedCategory,
    required this.assetImages,
    required this.pickedImages,
    this.descriptionError,
    this.imageError,
    this.originalCategory,
    this.originalDescription,
    required this.originalImages,
    this.currentDescription = '',
  });

  bool get isChanged {
    return selectedCategory != originalCategory ||
        currentDescription != (originalDescription ?? '') ||
        pickedImages.isNotEmpty ||
        assetImages.length != originalImages.length;
  }

  bool get hasError {
    return descriptionError != null || imageError != null;
  }

  ActivityEditorState copyWith({
    String? selectedCategory,
    List<String>? assetImages,
    List<File>? pickedImages,
    String? descriptionError,
    String? imageError,
    String? originalCategory,
    String? originalDescription,
    List<String>? originalImages,
    String? currentDescription,
  }) {
    return ActivityEditorState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      assetImages: assetImages ?? this.assetImages,
      pickedImages: pickedImages ?? this.pickedImages,
      descriptionError:
          descriptionError ??
          this.descriptionError, // ส่ง null มาเพื่อ clear error ได้
      imageError: imageError ?? this.imageError,
      originalCategory: originalCategory ?? this.originalCategory,
      originalDescription: originalDescription ?? this.originalDescription,
      originalImages: originalImages ?? this.originalImages,
      currentDescription: currentDescription ?? this.currentDescription,
    );
  }
}

// --- Map สี ---
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
class ActivityEditorNotifier
    extends AutoDisposeFamilyNotifier<ActivityEditorState, int> {
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  ActivityEditorState build(int id) {
    // โหลดข้อมูลจาก MockDB
    final activity = mockActivities.firstWhere((a) => a.id == id);

    // ตั้งค่า Controller
    descriptionController.text = activity.description;

    // Listen การพิมพ์เพื่อ update state และ validate
    descriptionController.addListener(_onTextChanged);

    // Dispose controller เมื่อ Provider ถูกทำลาย
    ref.onDispose(() {
      descriptionController.removeListener(_onTextChanged);
      descriptionController.dispose();
    });

    return ActivityEditorState(
      selectedCategory: activity.serviceCategoryName,
      assetImages: List<String>.from(activity.images),
      pickedImages: [],
      originalCategory: activity.serviceCategoryName,
      originalDescription: activity.description,
      originalImages: List<String>.from(activity.images),
      currentDescription: activity.description,
    );
  }

  void _onTextChanged() {
    // อัปเดต currentDescription เพื่อให้ UI รู้ว่า text เปลี่ยน (สำหรับปุ่ม Save)
    state = state.copyWith(currentDescription: descriptionController.text);
    validateFields();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    validateFields();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final newPicked = [...state.pickedImages, File(image.path)];
      state = state.copyWith(pickedImages: newPicked);
      validateFields();
    }
  }

  void removeAssetImage(int index) {
    final newAssets = [...state.assetImages];
    newAssets.removeAt(index);
    state = state.copyWith(assetImages: newAssets);
    validateFields();
  }

  void removePickedImage(int index) {
    final newPicked = [...state.pickedImages];
    newPicked.removeAt(index);
    state = state.copyWith(pickedImages: newPicked);
    validateFields();
  }

  void validateFields() {
    String? descriptionError;
    String? imageError;

    if (descriptionController.text.trim().isEmpty) {
      descriptionError = "กรุณากรอกข้อมูลให้ครบถ้วน";
    }

    if (state.assetImages.isEmpty && state.pickedImages.isEmpty) {
      imageError = "กรุณาเพิ่มรูปภาพ";
    }

    // การใช้ copyWith แบบนี้ ถ้าส่ง null ไปมันจะถือว่าไม่เปลี่ยนค่า
    // เราจึงต้อง trick นิดหน่อย หรือถ้า Model รองรับ nullable แล้วส่งค่าใหม่เข้าไป
    // ในที่นี้ Logic ของ copyWith ด้านบน: descriptionError ?? this.descriptionError
    // ดังนั้นถ้าเราอยาก Clear Error เราต้องระวัง

    // แก้ไข: สร้าง object ใหม่เลยเพื่อให้แน่ใจว่า error ถูก reset หรือ set ตามเงื่อนไข
    state = ActivityEditorState(
      selectedCategory: state.selectedCategory,
      assetImages: state.assetImages,
      pickedImages: state.pickedImages,
      originalCategory: state.originalCategory,
      originalDescription: state.originalDescription,
      originalImages: state.originalImages,
      currentDescription: state.currentDescription,
      // Update Errors
      descriptionError: descriptionError,
      imageError: imageError,
    );
  }
}

// --- Provider ---
final activityEditorProvider = NotifierProvider.autoDispose
    .family<ActivityEditorNotifier, ActivityEditorState, int>(
      ActivityEditorNotifier.new,
    );
