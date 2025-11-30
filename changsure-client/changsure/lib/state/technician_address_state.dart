import 'package:flutter/material.dart';
import '../models/address/address_model.dart';
import '../services/technician_address_service.dart';

class TechnicianAddressState extends ChangeNotifier {
  final TechnicianAddressService service;

  bool loading = false;
  List<AddressModel> addresses = [];

  TechnicianAddressState(this.service);

  AddressModel? get primary {
    try {
      return addresses.firstWhere((e) => e.isPrimary);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      addresses = await service.getMyAddresses();
    } catch (e) {
      addresses = [];
    }

    loading = false;
    notifyListeners();
  }

  Future<void> createAddress(Map<String, dynamic> payload) async {
    await service.createAddress(payload);
    await load();
  }

  Future<void> updatePrimaryAddress(
    int id,
    Map<String, dynamic> payload,
  ) async {
    await service.updateAddress(id, payload);
    await load();
  }
}
