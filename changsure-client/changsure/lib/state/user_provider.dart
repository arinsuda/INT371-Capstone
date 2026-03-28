import 'dart:io';
import 'package:changsure/state/notifications/realtime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:changsure/data/services/realtime_service.dart';

import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart';

import 'package:changsure/data/services/auth_service.dart';

import 'package:changsure/data/services/technician_service.dart' as tech;
import 'package:changsure/data/services/customer_service.dart' as cust;
import '../data/models/customer/customer_model.dart';
import '../data/models/technician/dashboard_model.dart';
import '../module/auth/technician/setup_technician_profile.dart';

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
        final profile = await authService.getTechnicianProfile(
          state!.token!,
          state!.id,
        );

        if (profile != null) {
          state = state!.copyWith(technicianProfile: profile);
        }
      } else if (state!.role == UserRole.customer) {
        final profile = await authService.getCustomerProfile(
          state!.token!,
          state!.id,
        );
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
        technicianId: state!.id,
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
    final user = state;
    if (user == null || user.token == null) return;

    try {
      if (user.role == UserRole.technician) {
        final addresses = await tech.TechnicianService().getAddresses(
          token: user.token!,
          technicianId: user.id,
        );
        state = user.copyWith(
          technicianProfile: user.technicianProfile?.copyWith(
            addresses: addresses,
          ),
        );
      } else if (user.role == UserRole.customer) {
        final addresses = await cust.CustomerService().getAddresses(
          token: user.token!,
          customerId: user.id,
        );
        state = user.copyWith(addresses: addresses);
      }
    } catch (e) {
      print("❌ Load Addresses Error: $e");
    }
  }

  Future<bool> saveTechnicianAddress({
    int? id,
    bool? isPrimary,
    String? label,
    String? phoneNumber,
    String? addressLine,
    String? houseNumber,
    String? village,
    String? moo,
    String? soi,
    String? road,
    required int provinceId,
    required int districtId,
    required int subDistrictId,
    required double lat,
    required double lng,
  }) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.technician) return false;

    final techId = state!.id;
    final service = tech.TechnicianService();

    try {
      final bool success = (id != null)
          ? await service.updateAddress(
              token: token,
              technicianId: techId,
              addressId: id,
              label: label,
              phoneNumber: phoneNumber,
              isPrimary: isPrimary,
              addressLine: addressLine,
              houseNumber: houseNumber,
              village: village,
              moo: moo,
              soi: soi,
              road: road,
              provinceId: provinceId,
              districtId: districtId,
              subDistrictId: subDistrictId,
              lat: lat,
              lng: lng,
            )
          : await service.createAddress(
              token: token,
              technicianId: techId,
              label: label,
              phoneNumber: phoneNumber,
              isPrimary: isPrimary,
              addressLine: addressLine,
              houseNumber: houseNumber,
              village: village,
              moo: moo,
              soi: soi,
              road: road,
              provinceId: provinceId,
              districtId: districtId,
              subDistrictId: subDistrictId,
              lat: lat,
              lng: lng,
            );

      if (success) await loadAddresses();
      return success;
    } catch (e) {
      print("❌ Save Technician Address Error: $e");
      return false;
    }
  }

  Future<bool> deleteTechnicianAddress(int addressId) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.technician) return false;

    try {
      final success = await tech.TechnicianService().deleteAddress(
        token: token,
        technicianId: state!.id,
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
    bool? isPrimary,
    String? label,
    String? phoneNumber,
    required String addressLine,
    required String zipCode,
    required int provinceId,
    required int districtId,
    required int subDistrictId,
    required double lat,
    required double lng,
  }) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.customer) return false;

    final cusId = state!.id;
    final service = cust.CustomerService();

    try {
      final bool success = (id != null)
          ? await service.updateAddress(
              token: token,
              customerId: cusId,
              addressId: id,
              label: label,
              phoneNumber: phoneNumber,
              isPrimary: isPrimary,
              addressLine: addressLine,
              provinceId: provinceId,
              districtId: districtId,
              subDistrictId: subDistrictId,
              lat: lat,
              lng: lng,
            )
          : await service.createAddress(
              token: token,
              customerId: cusId,
              addressLine: addressLine,
              phoneNumber: phoneNumber,
              label: label,
              isPrimary: isPrimary,
              provinceId: provinceId,
              districtId: districtId,
              subDistrictId: subDistrictId,
              lat: lat,
              lng: lng,
            );

      if (success) await loadAddresses();
      return success;
    } catch (e) {
      print("❌ Save Customer Address Error: $e");
      return false;
    }
  }

  Future<bool> deleteCustomerAddress(int addressId) async {
    final token = state?.token;
    if (token == null || state?.role != UserRole.customer) return false;

    try {
      final success = await cust.CustomerService().deleteAddress(
        token: token,
        customerId: state!.id,
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

final verifyProvider = StateNotifierProvider<VerifyNotifier, AsyncValue<void>>(
  (ref) => VerifyNotifier(ref),
);

class VerifyNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  VerifyNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<int?> verify(File file) async {
    state = const AsyncValue.loading();

    try {
      final registerData = ref.read(technicianRegisterDataProvider);
      print("Pre Verify $registerData");
      print("PreVerifyToken: ${registerData.preVerifiedToken}");

      if (registerData.preVerifiedToken == null) {
        throw Exception("No pre_verified_token");
      }

      final service = tech.TechnicianService();

      final jobId = await service.verifyTechnician(
        registerData.technicianId!,
        registerData.preVerifiedToken!,
        file,
      );

      state = const AsyncValue.data(null);

      return jobId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final verifyDetailProvider = FutureProvider.family<VerifyTechnician?, int>((
  ref,
  jobId,
) async {
  final user = ref.read(userProvider);

  if (user == null || user.token == null) return null;

  final service = tech.TechnicianService();

  return await service.getVerifyDetail(user.id, jobId, user.token!);
});

final passwordResetServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final requestOTPProvider = FutureProvider.family<OTPResponse, String>((
  ref,
  email,
) async {
  final service = ref.read(passwordResetServiceProvider);
  return service.requestOTP(email);
});

final verifyOTPProvider =
    FutureProvider.family<VerifyOTPResponse, VerifyOTPRequest>((
      ref,
      request,
    ) async {
      final service = ref.read(passwordResetServiceProvider);

      return service.verifyOTP(request);
    });

final resetPasswordProvider =
    FutureProvider.family<ResetPasswordResponse, ResetPasswordRequest>((
      ref,
      request,
    ) async {
      final service = ref.read(passwordResetServiceProvider);

      return service.resetPassword(request);
    });

final technicianServiceProvider = Provider<tech.TechnicianService>((ref) {
  return tech.TechnicianService();
});

final technicianReviewsProvider = FutureProvider.family<ReviewResponse, int>((
  ref,
  technicianId,
) async {
  final service = ref.read(technicianServiceProvider);
  final user = ref.watch(userProvider);

  if (user == null || user.token == null) {
    throw Exception('User not ready');
  }

  return service.getTechnicianReviews(technicianId, user.token!);
});

final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, AsyncValue<void>>(
      (ref) => ReviewNotifier(ref),
    );

class ReviewNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ReviewNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> createReview({
    required int bookingId,
    required int rating,
    String? comment,
    List<File>? images,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(userProvider);

      if (user == null || user.token == null) {
        throw Exception("User not logged in");
      }

      if (user.role != UserRole.customer) {
        throw Exception("Only customer can review");
      }

      final service = cust.CustomerService();

      await service.createReview(
        token: user.token!,
        // 🔥 ต้องใส่ token แล้ว
        customerId: user.id,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        images: images, // ✅ List<File>
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) async {
  final user = ref.watch(userProvider);

  if (user == null || user.token == null) {
    throw Exception("User not ready");
  }

  final service = ref.read(technicianServiceProvider);

  return service.getWalletSummary(token: user.token!, technicianId: user.id);
});
