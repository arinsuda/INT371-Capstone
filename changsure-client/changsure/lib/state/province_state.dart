import 'package:flutter/material.dart';
import '../services/province_service.dart';
import '../models/provinces/province.dart';

class ProvinceState extends ChangeNotifier {
  final ProvinceService repo;

  ProvinceState(this.repo);

  List<ProvinceResponse>? provinces;
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
