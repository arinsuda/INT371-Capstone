import 'package:flutter/material.dart';
import '../models/customers/customer_profile.dart';
import '../repositories/profile_repository.dart';

class ProfileState extends ChangeNotifier {
  final ProfileRepository repo;

  ProfileState(this.repo);

  Profile? profile;
  bool loading = false;
  String? error;

  Future<void> loadProfile() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await repo.getProfile();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
