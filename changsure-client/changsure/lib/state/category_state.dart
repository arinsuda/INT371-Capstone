import 'package:flutter/material.dart';
import 'package:changsure/models/service_categories/service_category.dart';
import 'package:changsure/services/service_category_service.dart';

class ServiceCategoryState extends ChangeNotifier {
  final ServiceCategoryService api;

  ServiceCategoryState(this.api);

  bool loading = false;
  List<ServiceCategoryModel>? categories;
  String? errorMessage;

  Future<void> loadCategories() async {
    try {
      loading = true;
      notifyListeners();

      categories = await api.fetchCategories();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
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
