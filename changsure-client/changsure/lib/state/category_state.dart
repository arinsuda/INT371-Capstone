import 'package:flutter/material.dart';
import 'package:changsure/models/service_categories/service_category.dart';
import 'package:changsure/services/service_category_service.dart';

class ServiceCategoryState extends ChangeNotifier {
  final ServiceCategoryService api;

  ServiceCategoryState(this.api);

  bool loading = false;
  List<ServiceCategoryModel>? categories;
  String? errorMessage;
  StackTrace? errorStack;

  Future<void> loadCategories() async {
    loading = true;
    errorMessage = null;
    errorStack = null;
    notifyListeners();

    try {
      final result = await api.fetchCategories();

      categories = result ?? [];
      errorMessage = null;
    } catch (e, stack) {
      errorMessage = "Category Error: $e";
      errorStack = stack;

      debugPrint("=== [CategoryState] loadCategories ERROR ===");
      debugPrint("Error: $e");
      debugPrint("Stack: $stack");

      categories = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  ServiceCategoryModel? getCategoryByName(String name) {
    final list = categories;
    if (list == null || list.isEmpty) return null;

    return list.firstWhere(
      (c) => c.catName.contains(name),
      orElse: () => list.first,
    );
  }
}
