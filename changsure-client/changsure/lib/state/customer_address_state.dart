import 'package:flutter/material.dart';
import 'package:changsure/models/address/address_model.dart';
import 'package:changsure/services/customer_address_service.dart';

class CustomerAddressState extends ChangeNotifier {
  final CustomerAddressService service;

  bool loading = false;
  List<AddressModel> addresses = [];

  CustomerAddressState(this.service);

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

  Future<void> savePrimaryAddress(Map<String, dynamic> payload) async {
    final p = primary;

    if (p == null) {
      payload["is_primary"] = true;
      await service.createAddress(payload);
    } else {
      await service.updateAddress(p.id, payload);
    }

    await load();
  }

  Future<void> setPrimary(int id) async {
    await service.setPrimary(id);
    await load();
  }
}
