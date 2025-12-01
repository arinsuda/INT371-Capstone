import 'package:flutter/material.dart';
import 'package:changsure/models/technicians/technician_activity.dart';
import 'package:changsure/services/technician_activity_service.dart';

class TechnicianWorkState extends ChangeNotifier {
  final TechnicianWorkService api;

  TechnicianWorkState(this.api);

  List<TechnicianWork> works = [];
  bool isLoading = false;
  String? errorMessage;

  TechnicianWork? currentWork;

  Future<void> loadWorks() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await api.listWorks();
      works = result.items;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadWorkById(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentWork = await api.getWork(id);
    } catch (e) {
      currentWork = null;
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> createWork(CreateTechnicianWorkDTO dto) async {
    try {
      final newWork = await api.createWork(dto);
      works.insert(0, newWork);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateWork(int id, UpdateTechnicianWorkDTO dto) async {
    try {
      final updated = await api.updateWork(id, dto);

      final index = works.indexWhere((w) => w.id == id);
      if (index != -1) {
        works[index] = updated;
      }

      if (currentWork?.id == id) {
        currentWork = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteWork(int id) async {
    try {
      await api.deleteWork(id);

      works.removeWhere((w) => w.id == id);

      if (currentWork?.id == id) {
        currentWork = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}
