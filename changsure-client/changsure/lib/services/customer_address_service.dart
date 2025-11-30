import 'package:changsure/api/api_client.dart';
import 'package:changsure/models/address/address_model.dart';

class CustomerAddressService {
  final ApiClient client;

  CustomerAddressService(this.client);

  Future<List<AddressModel>> getMyAddresses() async {
    final res = await client.dio.get("/me/addresses");

    final list = res.data["data"] as List;
    return list.map((e) => AddressModel.fromJson(e)).toList();
  }

  Future<AddressModel> createAddress(Map<String, dynamic> payload) async {
    final res = await client.dio.post("/me/addresses", data: payload);
    return AddressModel.fromJson(res.data["data"]);
  }

  Future<void> updateAddress(int id, Map<String, dynamic> payload) async {
    await client.dio.patch("/me/addresses/$id", data: payload);
  }

  Future<void> deleteAddress(int id) async {
    await client.dio.delete("/me/addresses/$id");
  }

  Future<void> setPrimary(int id) async {
    await client.dio.patch("/me/addresses/$id/primary");
  }
}
