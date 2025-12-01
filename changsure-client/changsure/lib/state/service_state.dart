import 'package:flutter/material.dart';
import 'package:changsure/models/services/service.dart';
import 'package:changsure/services/service_service.dart';

class ServiceState extends ChangeNotifier {
  final ServiceApi api;

  List<ServiceModel> services = [];
  bool loading = false;
  String? error;
  StackTrace? errorStack;

  ServiceState({required this.api});

  Future<void> loadServices({
    String? search,
    int? categoryId,
    bool? isActive,
  }) async {
    loading = true;
    error = null;
    errorStack = null;
    notifyListeners();

    try {
      final result = await api.listServices(
        search: search,
        categoryId: categoryId,
        isActive: isActive,
      );

      // ป้องกัน API คืน null
      services = (result ?? []);
    } catch (e, stack) {
      error = "Service Error: $e";
      errorStack = stack;

      debugPrint("=== [ServiceState] loadServices ERROR ===");
      debugPrint("Error: $e");
      debugPrint("Stack: $stack");

      services = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchServices({int? categoryId}) async {
    await loadServices(categoryId: categoryId, isActive: true);
  }

  Future<ServiceModel?> getById(int id) async {
    try {
      return await api.getService(id);
    } catch (e, stack) {
      debugPrint("=== [ServiceState] getById ERROR ===");
      debugPrint("Error: $e");
      debugPrint("Stack: $stack");
      return null;
    }
  }
}
