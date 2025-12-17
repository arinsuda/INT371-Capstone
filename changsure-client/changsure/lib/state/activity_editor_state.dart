import 'dart:io';
import 'package:changsure/data/services/technician_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'user_provider.dart';

class ActivityEditorState {
  final bool isLoading;
  final int? serviceId;
  final String? selectedCategory;

  final List<String> assetImages;
  final List<int> assetImageIds;
  final List<File> pickedImages;

  final List<int> idsToDelete;

  final String? descriptionError;
  final String? imageError;

  final int? originalServiceId;
  final String? originalDescription;

  final String currentDescription;

  const ActivityEditorState({
    this.isLoading = false,
    this.serviceId,
    this.selectedCategory,
    required this.assetImages,
    required this.assetImageIds,
    required this.pickedImages,
    required this.idsToDelete,
    this.descriptionError,
    this.imageError,
    this.originalServiceId,
    this.originalDescription,
    this.currentDescription = '',
  });

  bool get isChanged {
    if (originalServiceId == null) {
      return currentDescription.isNotEmpty ||
          pickedImages.isNotEmpty ||
          serviceId != null;
    }

    return serviceId != originalServiceId ||
        currentDescription != (originalDescription ?? '') ||
        pickedImages.isNotEmpty ||
        idsToDelete.isNotEmpty;
  }

  bool get hasError {
    return descriptionError != null || imageError != null;
  }

  ActivityEditorState copyWith({
    bool? isLoading,
    int? serviceId,
    String? selectedCategory,
    List<String>? assetImages,
    List<int>? assetImageIds,
    List<File>? pickedImages,
    List<int>? idsToDelete,
    String? descriptionError,
    String? imageError,
    int? originalServiceId,
    String? originalDescription,
    String? currentDescription,
  }) {
    return ActivityEditorState(
      isLoading: isLoading ?? this.isLoading,
      serviceId: serviceId ?? this.serviceId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      assetImages: assetImages ?? this.assetImages,
      assetImageIds: assetImageIds ?? this.assetImageIds,
      pickedImages: pickedImages ?? this.pickedImages,
      idsToDelete: idsToDelete ?? this.idsToDelete,
      descriptionError: descriptionError ?? this.descriptionError,
      imageError: imageError ?? this.imageError,
      originalServiceId: originalServiceId ?? this.originalServiceId,
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
    final post = await service.getPostById(user!.token!, id);

    if (post != null) {
      descriptionController.text = post.content;

      List<int> mockIds = List.generate(post.images.length, (index) => 0);

      state = state.copyWith(
        isLoading: false,
        serviceId: post.serviceId,
        selectedCategory: post.categoryName,
        assetImages: post.images,
        assetImageIds: mockIds,
        originalServiceId: post.serviceId,
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
        serviceId: state.serviceId,
        selectedCategory: state.selectedCategory,
        assetImages: state.assetImages,
        assetImageIds: state.assetImageIds,
        pickedImages: state.pickedImages,
        idsToDelete: state.idsToDelete,
        originalServiceId: state.originalServiceId,
        originalDescription: state.originalDescription,
        currentDescription: state.currentDescription,
        descriptionError: null,
        imageError: state.imageError,
      );
    }
  }

  void setService(int id, String name) {
    state = state.copyWith(serviceId: id, selectedCategory: name);
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
        serviceId: state.serviceId,
        selectedCategory: state.selectedCategory,
        assetImages: state.assetImages,
        assetImageIds: state.assetImageIds,
        pickedImages: newPicked,
        idsToDelete: state.idsToDelete,
        originalServiceId: state.originalServiceId,
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

    int deletedId = newAssetIds.removeAt(index);

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

    if (state.serviceId == null) {}

    if (descriptionError != null || imageError != null) {
      state = ActivityEditorState(
        isLoading: state.isLoading,
        serviceId: state.serviceId,
        selectedCategory: state.selectedCategory,
        assetImages: state.assetImages,
        assetImageIds: state.assetImageIds,
        pickedImages: state.pickedImages,
        idsToDelete: state.idsToDelete,
        originalServiceId: state.originalServiceId,
        originalDescription: state.originalDescription,
        currentDescription: state.currentDescription,
        descriptionError: descriptionError,
        imageError: imageError,
      );
      return false;
    }

    final user = ref.read(userProvider);
    final service = TechnicianService();

    state = state.copyWith(isLoading: true);
    bool success = false;

    if (isCreateMode) {
      success = await service.createPost(
        token: user!.token!,
        description: descriptionController.text,
        serviceId: state.serviceId!,

        provinceId: user.technicianProfile?.provinces.firstOrNull?.id ?? 1,
        images: state.pickedImages,
      );
    } else {
      success = await service.updatePost(
        token: user!.token!,
        postId: arg,
        description: descriptionController.text,
        serviceId: state.serviceId,
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
