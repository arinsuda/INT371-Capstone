import 'package:flutter/material.dart';

import '../models/customers/customer_profile.dart';
import '../models/customers/update_customer_request.dart';
import '../models/technicians/technician_profile.dart';
import '../models/technicians/update_technician_request.dart';
import '../services/profile_service.dart';
import '../state/auth_state.dart';

class ProfileState extends ChangeNotifier {
  final ProfileService service;
  final AuthState auth;

  ProfileState(this.service, this.auth);

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
        technicianProfile = await service.getTechnicianProfile();
        customerProfile = null;
      } else {
        customerProfile = await service.getCustomerProfile();
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
        await service.updateTechnicianProfile(
          TechnicianProfileRequest(
            firstname: firstname,
            lastname: lastname,
            email: email,
            phone: phone,
            bio: bio ?? technicianProfile?.bio ?? "",
          ),
        );
      } else {
        await service.updateCustomerProfile(
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

      await service.updateTechnicianProvinces(provinceIds);

      await loadProfile();

      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> changeAvatar(String filePath) async {
    try {
      loading = true;
      notifyListeners();

      final url = await service.uploadTechnicianAvatar(filePath);

      await service.updateTechnicianAvatarURL(url);

      await loadProfile();
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
