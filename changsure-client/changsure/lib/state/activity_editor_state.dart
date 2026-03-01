import 'dart:io';
import 'package:changsure/data/services/technician_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'user_provider.dart';

class ActivityEditorState {
  final bool isLoading;

  final int? categoryId;
  final String? selectedCategory;

  final List<String> assetImages;
  final List<int> assetImageIds;
  final List<File> pickedImages;

  final List<int> idsToDelete;

  final String? descriptionError;
  final String? imageError;

  final int? originalCategoryId;
  final String? originalDescription;

  final String currentDescription;

  const ActivityEditorState({
    this.isLoading = false,
    this.categoryId,
    this.selectedCategory,
    required this.assetImages,
    required this.assetImageIds,
    required this.pickedImages,
    required this.idsToDelete,
    this.descriptionError,
    this.imageError,
    this.originalCategoryId,
    this.originalDescription,
    this.currentDescription = '',
  });

  bool get isChanged {
    if (originalCategoryId == null) {
      return currentDescription.isNotEmpty ||
          pickedImages.isNotEmpty ||
          categoryId != null;
    }

    return categoryId != originalCategoryId ||
        currentDescription != (originalDescription ?? '') ||
        pickedImages.isNotEmpty ||
        idsToDelete.isNotEmpty;
  }

  bool get hasError {
    return descriptionError != null || imageError != null;
  }

  ActivityEditorState copyWith({
    bool? isLoading,
    int? categoryId,
    String? selectedCategory,
    List<String>? assetImages,
    List<int>? assetImageIds,
    List<File>? pickedImages,
    List<int>? idsToDelete,
    String? descriptionError,
    String? imageError,
    int? originalCategoryId,
    String? originalDescription,
    String? currentDescription,
  }) {
    return ActivityEditorState(
      isLoading: isLoading ?? this.isLoading,
      categoryId: categoryId ?? this.categoryId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      assetImages: assetImages ?? this.assetImages,
      assetImageIds: assetImageIds ?? this.assetImageIds,
      pickedImages: pickedImages ?? this.pickedImages,
      idsToDelete: idsToDelete ?? this.idsToDelete,
      descriptionError: descriptionError ?? this.descriptionError,
      imageError: imageError ?? this.imageError,
      originalCategoryId: originalCategoryId ?? this.originalCategoryId,
      originalDescription: originalDescription ?? this.originalDescription,
      currentDescription: currentDescription ?? this.currentDescription,
    );
  }
}

class ActivityEditorNotifier
    extends AutoDisposeFamilyNotifier<ActivityEditorState, int> {
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool get isCreateMode => arg <= 0;

  @override
  ActivityEditorState build(int id) {
    final initialState = ActivityEditorState(
      isLoading: !isCreateMode,
      assetImages: [],
      assetImageIds: [],
      pickedImages: [],
      idsToDelete: [],
    );

    descriptionController.addListener(_onTextChanged);

    ref.onDispose(() {
      descriptionController.removeListener(_onTextChanged);
      descriptionController.dispose();
    });

    if (!isCreateMode) {
      Future.microtask(() => _loadPostData(id));
    }

    return initialState;
  }

  Future<void> _loadPostData(int id) async {
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    final service = TechnicianService();
    final post = await service.getPostById(
      token: user!.token!,
      technicianId: user.id,
      postId: id,
    );

    if (post != null) {
      descriptionController.text = post.content;

      state = state.copyWith(
        isLoading: false,
        categoryId: post.categoryId,
        selectedCategory: post.categoryName,
        assetImages: post.images,
        assetImageIds: post.imageIds,
        originalCategoryId: post.categoryId,
        originalDescription: post.content,
        currentDescription: post.content,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void _onTextChanged() {
    state = state.copyWith(currentDescription: descriptionController.text);

    if (state.descriptionError != null) {
      state = ActivityEditorState(
        isLoading: state.isLoading,
        categoryId: state.categoryId,
        selectedCategory: state.selectedCategory,
        assetImages: state.assetImages,
        assetImageIds: state.assetImageIds,
        pickedImages: state.pickedImages,
        idsToDelete: state.idsToDelete,
        originalCategoryId: state.originalCategoryId,
        originalDescription: state.originalDescription,
        currentDescription: state.currentDescription,
        descriptionError: null,
        imageError: state.imageError,
      );
    }
  }

  void setCategory(int id, String name) {
    state = state.copyWith(categoryId: id, selectedCategory: name);
  }

  Future<void> pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final newPicked = [
        ...state.pickedImages,
        ...images.map((e) => File(e.path)),
      ];

      state = ActivityEditorState(
        isLoading: state.isLoading,
        categoryId: state.categoryId,
        selectedCategory: state.selectedCategory,
        assetImages: state.assetImages,
        assetImageIds: state.assetImageIds,
        pickedImages: newPicked,
        idsToDelete: state.idsToDelete,
        originalCategoryId: state.originalCategoryId,
        originalDescription: state.originalDescription,
        currentDescription: state.currentDescription,
        descriptionError: state.descriptionError,
        imageError: null,
      );
    }
  }

  void removeAssetImage(int index) {
    final newAssets = [...state.assetImages];
    final newAssetIds = [...state.assetImageIds];

    newAssets.removeAt(index);
    final deletedId = newAssetIds.removeAt(index);

    final newIdsToDelete = [...state.idsToDelete];
    if (deletedId > 0) {
      newIdsToDelete.add(deletedId);
    }

    state = state.copyWith(
      assetImages: newAssets,
      assetImageIds: newAssetIds,
      idsToDelete: newIdsToDelete,
    );
  }

  void removePickedImage(int index) {
    final newPicked = [...state.pickedImages];
    newPicked.removeAt(index);
    state = state.copyWith(pickedImages: newPicked);
  }

  Future<bool> savePost() async {
    String? descriptionError;
    String? imageError;

    if (descriptionController.text.trim().isEmpty) {
      descriptionError = "กรุณากรอกข้อมูลให้ครบถ้วน";
    }

    if (state.assetImages.isEmpty && state.pickedImages.isEmpty) {
      imageError = "กรุณาเพิ่มรูปภาพ";
    }

    if (descriptionError != null || imageError != null) {
      state = ActivityEditorState(
        isLoading: state.isLoading,
        categoryId: state.categoryId,
        selectedCategory: state.selectedCategory,
        assetImages: state.assetImages,
        assetImageIds: state.assetImageIds,
        pickedImages: state.pickedImages,
        idsToDelete: state.idsToDelete,
        originalCategoryId: state.originalCategoryId,
        originalDescription: state.originalDescription,
        currentDescription: state.currentDescription,
        descriptionError: descriptionError,
        imageError: imageError,
      );
      return false;
    }

    final user = ref.read(userProvider);
    if (user?.token == null) return false;

    final service = TechnicianService();

    state = state.copyWith(isLoading: true);
    bool success = false;

    if (isCreateMode) {
      // BE ต้องการ title เป็น required — ใช้ description แรก 50 ตัวอักษรเป็น title
      final desc = descriptionController.text.trim();
      final title = desc.length > 50 ? desc.substring(0, 50) : desc;

      success = await service.createPost(
        token: user!.token!,
        technicianId: user.id,
        title: title,
        description: desc,
        categoryId: state.categoryId,
        images: state.pickedImages,
      );
    } else {
      success = await service.updatePost(
        token: user!.token!,
        technicianId: user.id,
        postId: arg,
        description: descriptionController.text.trim(),
        categoryId: state.categoryId,
        newImages: state.pickedImages,
        imageIdsToDelete: state.idsToDelete,
      );
    }

    state = state.copyWith(isLoading: false);
    return success;
  }
}

final activityEditorProvider = NotifierProvider.autoDispose
    .family<ActivityEditorNotifier, ActivityEditorState, int>(
      ActivityEditorNotifier.new,
    );
