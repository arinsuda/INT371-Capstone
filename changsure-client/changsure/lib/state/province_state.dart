import 'package:flutter/material.dart';
import '../repositories/province_repository.dart';

class ProvinceState extends ChangeNotifier {
  final ProvinceRepository repo;

  ProvinceState(this.repo);

  List<String>? provinces;
  bool loading = false;
  String? error;

  Future<void> loadProvinces() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      provinces = await repo.getProvinces();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
