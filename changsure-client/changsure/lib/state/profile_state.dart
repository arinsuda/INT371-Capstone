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

  String? get avatarUrl =>
      isTechnician ? technicianProfile?.avatarUrl : customerProfile?.avatarUrl;

  String? get displayName => isTechnician
      ? '${technicianProfile?.firstname ?? ''} ${technicianProfile?.lastname ?? ''}'
            .trim()
      : '${customerProfile?.firstname ?? ''} ${customerProfile?.lastname ?? ''}'
            .trim();

  String? get email =>
      isTechnician ? technicianProfile?.email : customerProfile?.email;

  String? get phone =>
      isTechnician ? technicianProfile?.phone : customerProfile?.phone;

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
      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint('Error loading profile: $e');
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
      debugPrint('Error updating profile: $e');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTechnicianProvinces(List<int> provinceIds) async {
    if (!isTechnician) {
      error = 'เฉพาะช่างเท่านั้นที่สามารถอัปเดตจังหวัดได้';
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      await service.updateTechnicianProvinces(provinceIds);

      await loadProfile();
      return true;
    } catch (e) {
      error = e.toString();
      debugPrint('Error updating provinces: $e');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeAvatar(String filePath) async {
    if (!isTechnician) {
      error = 'เฉพาะช่างเท่านั้นที่สามารถเปลี่ยนรูปโปรไฟล์ได้';
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final url = await service.uploadTechnicianAvatar(filePath);

      await service.updateTechnicianAvatarURL(url);

      await loadProfile();
      return true;
    } catch (e) {
      error = e.toString();
      debugPrint('Error changing avatar: $e');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    await loadProfile();
  }

  void clear() {
    customerProfile = null;
    technicianProfile = null;
    error = null;
    loading = false;
    notifyListeners();
  }
}
