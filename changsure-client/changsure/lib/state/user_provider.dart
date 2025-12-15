import 'package:changsure/data/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/data/services/address_service.dart';
import 'package:changsure/data/models/address_model.dart';

final userProvider = NotifierProvider<UserNotifier, UserModel?>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    return null;
  }

  void login(UserModel user) {
    state = user;
  }

  void logout() {
    state = null;
  }

  void updateTechnicianProfile(TechnicianModel newProfile) {
    if (state != null && state!.role == UserRole.technician) {
      state = state!.copyWith(technicianProfile: newProfile);
    }
  }

  Future<void> refreshUser() async {
    if (state?.token == null || state?.role != UserRole.technician) return;

    try {
      final authService = AuthService();
      final newTechProfile = await authService.getTechnicianProfile(
        state!.token!,
      );

      if (newTechProfile != null) {
        state = state!.copyWith(technicianProfile: newTechProfile);
        print(
          "✅ Refresh Profile Success: Badge count = ${newTechProfile.badges.length}",
        );
      }
    } catch (e) {
      print("❌ Refresh Error: $e");
    }
  }

  
}
