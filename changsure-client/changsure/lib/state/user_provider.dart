import 'dart:io';
import 'package:changsure/state/notifications/realtime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:changsure/data/services/realtime_service.dart';

import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart';

import 'package:changsure/data/services/auth_service.dart';
import 'package:changsure/data/services/address_service.dart';

import 'package:changsure/data/services/technician_service.dart' as tech;
import 'package:changsure/data/services/customer_service.dart' as cust;

import '../data/models/customer/customer_model.dart';

final userProvider = NotifierProvider<UserNotifier, UserModel?>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    checkLoginStatus();
    return null;
  }

  RealtimeService get _realtime => ref.read(realtimeServiceProvider);
  
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (accessToken == null || refreshToken == null) return;

    if (JwtDecoder.isExpired(accessToken)) {
      final authService = AuthService();
      final newTokens = await authService.refreshToken(refreshToken);

      if (newTokens != null) {
        final newAccess = newTokens['access_token'];
        final newRefresh = newTokens['refresh_token'] ?? refreshToken;

        await _saveTokens(newAccess, newRefresh);
        await _loadUserFromToken(newAccess);
      } else {
        await logout();
      }
    } else {
      await _loadUserFromToken(accessToken);
    }
  }

  Future<void> _loadUserFromToken(String token) async {
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      UserRole role = UserRole.customer;
      if (decodedToken['role'] == 'technician' ||
          decodedToken['user_role'] == 'technician') {
        role = UserRole.technician;
      }

      final dynamic rawId = decodedToken['user_id'] ?? decodedToken['sub'];
      final int userId = (rawId is int)
          ? rawId
          : int.tryParse(rawId.toString()) ?? 0;

      state = UserModel(id: userId, token: token, role: role);

      await refreshUser();
      await loadAddresses();

      _realtime.connect(
        token: token,
        role: state!.role == UserRole.technician
            ? RealtimeRole.technician
            : RealtimeRole.customer,
      );
    } catch (e) {
      await logout();
    }
  }

  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> login(UserModel user, String refreshToken) async {
    state = user;

    await _saveTokens(user.token!, refreshToken);
    await refreshUser();
    await loadAddresses();

    _realtime.connect(
      token: user.token!,
      role: user.role == UserRole.technician
          ? RealtimeRole.technician
          : RealtimeRole.customer,
    );
  }

  Future<void> logout() async {
    state = null;
    _realtime.disconnect();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void updateTechnicianProfile(TechnicianModel newProfile) {
    if (state != null && state!.role == UserRole.technician) {
      state = state!.copyWith(technicianProfile: newProfile);
    }
  }

  void updateCustomerProfile(CustomerModel customer) {
    if (state == null) return;

    state = state!.copyWith(customerProfile: customer);
  }

  Future<void> refreshUser() async {
    if (state?.token == null) return;

    try {
      final authService = AuthService();

      if (state!.role == UserRole.technician) {
        final profile = await authService.getTechnicianProfile(state!.token!);
        if (profile != null) {
          state = state!.copyWith(technicianProfile: profile);
        }
      } else if (state!.role == UserRole.customer) {
        final profile = await authService.getCustomerProfile(state!.token!);
        if (profile != null) {
          state = state!.copyWith(customerProfile: profile);
        }
      }
    } catch (e) {
      print("❌ Refresh Error: $e");
    }
  }

  Future<bool> saveTechnicianProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? bio,
    List<int>? provinceIds,
    List<Map<String, dynamic>>? services,
    File? avatarFile,
  }) async {
    if (state == null ||
        state!.token == null ||
        state!.role != UserRole.technician) {
      return false;
    }

    try {
      final service = tech.TechnicianService();

      final success = await service.updateProfile(
        token: state!.token!,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        bio: bio,
        provinceIds: provinceIds,
        services: services,
        avatarFile: avatarFile,
      );

      if (success) {
        await refreshUser();
        return true;
      }
    } catch (e) {
      print("❌ Save Technician Profile Error: $e");
    }
    return false;
  }

  Future<void> loadAddresses() async {
    if (state == null || state!.token == null) return;

    try {
      final addressService = AddressService();
      final addresses = await addressService.getAddresses(
        state!.token!,
        state!.role,
      );

      if (state!.role == UserRole.technician &&
          state!.technicianProfile != null) {
        final newTechProfile = state!.technicianProfile!.copyWith(
          addresses: addresses,
        );
        state = state!.copyWith(technicianProfile: newTechProfile);
      } else if (state!.role == UserRole.customer) {
        state = state!.copyWith(addresses: addresses);
      }

      print("✅ Load Addresses Success: ${addresses.length} items");
    } catch (e) {
      print("❌ Load Addresses Error: $e");
    }
  }

  Future<bool> saveTechnicianAddress({
    int? id,
    required String houseNumber,
    required String subDistrict,
    required String district,
    required String province,
    required String zipCode,

    int? provinceId,
    int? districtId,
    int? subDistrictId,

    double? lat,
    double? lng,
  }) async {
    final token = state?.token;
    if (token == null) return false;

    final service = tech.TechnicianService();

    bool success;
    try {
      if (id != null) {
        success = await service.updateAddress(
          token: token,
          addressId: id,
          houseNumber: houseNumber,
          subDistrict: subDistrict,
          district: district,
          province: province,
          postCode: zipCode,

          provinceId: provinceId,
          districtId: districtId,
          subDistrictId: subDistrictId,

          lat: lat,
          lng: lng,
        );
      } else {
        success = await service.createAddress(
          token: token,
          houseNumber: houseNumber,
          subDistrict: subDistrict,
          district: district,
          province: province,
          postCode: zipCode,
          isPrimary: true,

          provinceId: provinceId,
          districtId: districtId,
          subDistrictId: subDistrictId,

          lat: lat,
          lng: lng,
        );
      }

      if (success) {
        await loadAddresses();
      }
      return success;
    } catch (e) {
      print("❌ Save Address Error: $e");
      return false;
    }
  }

  Future<bool> deleteTechnicianAddress(int addressId) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.technician) {
      return false;
    }

    final service = tech.TechnicianService();

    try {
      final success = await service.deleteAddress(
        token: token,
        addressId: addressId,
      );

      if (success) {
        await loadAddresses();
        print("✅ Delete Technician Address Success");
      }

      return success;
    } catch (e) {
      print("❌ Delete Technician Address Error: $e");
      return false;
    }
  }

  Future<bool> saveCustomerAddress({
    int? id,
    required String houseNumber,
    required String subDistrict,
    required String district,
    required String province,
    required String zipCode,

    int? provinceId,
    int? districtId,
    int? subDistrictId,

    double? lat,
    double? lng,
  }) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.customer) {
      return false;
    }

    final service = cust.CustomerService();

    bool success = false;
    try {
      if (id != null) {
        success = await service.updateAddress(
          token: token,
          addressId: id,
          houseNumber: houseNumber,
          subDistrict: subDistrict,
          district: district,
          province: province,
          postCode: zipCode,

          provinceId: provinceId,
          districtId: districtId,
          subDistrictId: subDistrictId,

          lat: lat,
          lng: lng,
        );
      } else {
        success = await service.createAddress(
          token: token,
          houseNumber: houseNumber,
          subDistrict: subDistrict,
          district: district,
          province: province,
          postCode: zipCode,
          isPrimary: true,

          provinceId: provinceId,
          districtId: districtId,
          subDistrictId: subDistrictId,

          lat: lat,
          lng: lng,
        );
      }

      if (success) {
        await loadAddresses();
      }

      return success;
    } catch (e) {
      print("❌ Save Customer Address Error: $e");
      return false;
    }
  }

  Future<bool> deleteCustomerAddress(int addressId) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.customer) {
      return false;
    }

    final service = cust.CustomerService();

    try {
      final success = await service.deleteAddress(
        token: token,
        addressId: addressId,
      );

      if (success) {
        await loadAddresses();
        print("✅ Delete Customer Address Success");
      }

      return success;
    } catch (e) {
      print("❌ Delete Customer Address Error: $e");
      return false;
    }
  }
}
