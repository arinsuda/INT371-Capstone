import 'package:flutter/material.dart';
import 'package:changsure/models/services/service.dart';
import 'package:changsure/services/service_service.dart';

class ServiceState extends ChangeNotifier {
  final ServiceApi api;

  List<ServiceModel> services = [];
  bool loading = false;
  String? error;

  ServiceState({required this.api});

  Future<void> loadServices({
    String? search,
    int? categoryId,
    bool? isActive,
  }) async {
    try {
      loading = true;
      notifyListeners();

      final result = await api.listServices(
        search: search,
        categoryId: categoryId,
        isActive: isActive,
      );

      services = result;
      error = null;
    } catch (e) {
      error = e.toString();
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
    } catch (_) {
      return null;
    }
  }
}
