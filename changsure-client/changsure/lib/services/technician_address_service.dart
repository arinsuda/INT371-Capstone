import 'package:dio/dio.dart';
import '../api/api_client.dart';
import 'package:changsure/models/address/address_model.dart';

class TechnicianAddressService {
  final ApiClient client;

  TechnicianAddressService(this.client);

  Future<List<AddressModel>> getMyAddresses() async {
    final res = await client.dio.get("/technicians/me/addresses");

    final data = res.data["data"] as List;
    return data.map((e) => AddressModel.fromJson(e)).toList();
  }

  Future<void> createAddress(Map<String, dynamic> data) async {
    await client.dio.post("/technicians/me/addresses", data: data);
  }

  Future<void> updateAddress(int id, Map<String, dynamic> payload) async {
    await client.dio.patch("/technicians/me/addresses/$id", data: payload);
  }
  
  Future<void> setPrimary(int id) async {
    await client.dio.patch("/technicians/me/addresses/$id/primary");
  }
}
