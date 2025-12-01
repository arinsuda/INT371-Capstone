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

  String? get displayName {
    if (isTechnician) {
      final tech = technicianProfile;
      if (tech == null) return null;
      return '${tech.firstname} ${tech.lastname}'.trim();
    } else {
      final customer = customerProfile;
      if (customer == null) return null;
      return '${customer.firstname} ${customer.lastname}'.trim();
    }
  }

  String? get email =>
      isTechnician ? technicianProfile?.email : customerProfile?.email;

  String? get phone =>
      isTechnician ? technicianProfile?.phone : customerProfile?.phone;

  bool get hasProfile =>
      isTechnician ? technicianProfile != null : customerProfile != null;

  Future<void> loadProfile() async {
    _setLoadingState(true);

    try {
      if (isTechnician) {
        await _loadTechnicianProfile();
      } else {
        await _loadCustomerProfile();
      }
      error = null;
    } catch (e, stackTrace) {
      _handleError('Error loading profile', e, stackTrace);
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _loadTechnicianProfile() async {
    try {
      final response = await service.getTechnicianProfile();
      debugPrint('✅ Technician profile loaded: ${response.id}');

      technicianProfile = response;
      customerProfile = null;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to parse technician profile');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _loadCustomerProfile() async {
    try {
      final response = await service.getCustomerProfile();
      debugPrint('✅ Customer profile loaded: ${response.id}');

      customerProfile = response;
      technicianProfile = null;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to parse customer profile');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> updateProfile({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    String? bio,
  }) async {
    _setLoadingState(true);

    try {
      if (isTechnician) {
        await _updateTechnicianProfile(
          firstname: firstname,
          lastname: lastname,
          email: email,
          phone: phone,
          bio: bio,
        );
      } else {
        await _updateCustomerProfile(
          firstname: firstname,
          lastname: lastname,
          email: email,
          phone: phone,
        );
      }

      await loadProfile();
      return true;
    } catch (e, stackTrace) {
      _handleError('Error updating profile', e, stackTrace);
      return false;
    }
  }

  Future<void> _updateTechnicianProfile({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    String? bio,
  }) async {
    await service.updateTechnicianProfile(
      TechnicianProfileRequest(
        firstname: firstname,
        lastname: lastname,
        email: email,
        phone: phone,
        bio: bio ?? technicianProfile?.bio ?? '',
      ),
    );
  }

  Future<void> _updateCustomerProfile({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
  }) async {
    await service.updateCustomerProfile(
      UpdateCustomerRequest(
        firstname: firstname,
        lastname: lastname,
        email: email,
        phone: phone,
      ),
    );
  }

  Future<bool> updateTechnicianProvinces(List<int> provinceIds) async {
    if (!isTechnician) {
      error = 'เฉพาะช่างเท่านั้นที่สามารถอัปเดตจังหวัดได้';
      notifyListeners();
      return false;
    }

    _setLoadingState(true);

    try {
      await service.updateTechnicianProvinces(provinceIds);
      await loadProfile();
      return true;
    } catch (e, stackTrace) {
      _handleError('Error updating provinces', e, stackTrace);
      return false;
    }
  }

  Future<bool> changeAvatar(String filePath) async {
    if (!isTechnician) {
      error = 'เฉพาะช่างเท่านั้นที่สามารถเปลี่ยนรูปโปรไฟล์ได้';
      notifyListeners();
      return false;
    }

    _setLoadingState(true);

    try {
      final url = await service.uploadTechnicianAvatar(filePath);
      await service.updateTechnicianAvatarURL(url);
      await loadProfile();
      return true;
    } catch (e, stackTrace) {
      _handleError('Error changing avatar', e, stackTrace);
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

  void _setLoadingState(bool isLoading) {
    loading = isLoading;
    if (isLoading) {
      error = null;
    }
    notifyListeners();
  }

  void _handleError(String context, Object error, StackTrace stackTrace) {
    this.error = error.toString();

    debugPrint('❌ $context: $error');
    debugPrint('📍 StackTrace: $stackTrace');

    if (error.toString().contains('type') &&
        error.toString().contains('subtype')) {
      debugPrint(
        '⚠️  This looks like a type casting error. Check your model parsing.',
      );
    }

    loading = false;
    notifyListeners();
  }

  // เพิ่มใน ProfileState
  Future<bool> updateTechnicianServices(
    List<Map<String, dynamic>> servicesData,
  ) async {
    if (!isTechnician) {
      error = 'เฉพาะช่างเท่านั้นที่สามารถอัปเดต Services ได้';
      notifyListeners();
      return false;
    }

    _setLoadingState(true);

    try {
      await service.updateTechnicianServices(servicesData);
      await loadProfile(); // ⭐ โหลดข้อมูลใหม่
      return true;
    } catch (e, stackTrace) {
      _handleError('Error updating services', e, stackTrace);
      return false;
    }
  }
}
