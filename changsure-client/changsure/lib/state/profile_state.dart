import 'package:flutter/material.dart';

import '../models/customers/customer_profile.dart';
import '../models/customers/update_customer_request.dart';
import '../models/technicians/technician_profile.dart';
import '../models/technicians/update_technician_request.dart';
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
        technicianProfile = await repo.getTechnicianProfile();
        customerProfile = null;
      } else {
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

  Future<bool> updateProfile({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    String? bio,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      if (isTechnician) {
        await repo.updateTechnicianProfile(
          TechnicianProfileRequest(
            firstname: firstname,
            lastname: lastname,
            email: email,
            phone: phone,
            bio: bio ?? technicianProfile?.bio ?? "",
          ),
        );
      } else {
        await repo.updateCustomerProfile(
          UpdateCustomerRequest(
            firstname: firstname,
            lastname: lastname,
            email: email,
            phone: phone,
          ),
        );
      }

      await loadProfile();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTechnicianProvinces(List<int> provinceIds) async {
    try {
      loading = true;
      notifyListeners();

      await repo.updateTechnicianProvinces(provinceIds);

      await loadProfile();

      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
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
