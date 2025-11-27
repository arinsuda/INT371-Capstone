import 'package:flutter/material.dart';

import '../models/customers/customer_profile.dart';
import '../models/technicians/technician_profile.dart';
import '../repositories/profile_repository.dart';
import '../state/auth_state.dart';

class ProfileState extends ChangeNotifier {
  final ProfileRepository repo;
  final AuthState auth;

  ProfileState(this.repo, this.auth);

  CustomerProfile? customerProfile;
  TechnicianProfile? technicianProfile;

  bool loading = false;
  String? error;

  bool get isTechnician => auth.role == 'technician';

  Future<void> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      if (isTechnician) {
        // 👉 สำหรับช่าง ยิง /technicians/profile
        technicianProfile = await repo.getTechnicianProfile();
        customerProfile = null;
      } else {
        // 👉 สำหรับลูกค้า ยิง /customers/profile
        customerProfile = await repo.getCustomerProfile();
        technicianProfile = null;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void clear() {
    customerProfile = null;
    technicianProfile = null;
    error = null;
    loading = false;
    notifyListeners();
  }
}
