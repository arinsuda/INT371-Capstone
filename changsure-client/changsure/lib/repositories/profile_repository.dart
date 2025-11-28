import '../api/api_client.dart';
import '../models/customers/customer_profile.dart';
import '../models/customers/update_customer_request.dart';
import '../models/technicians/technician_profile.dart';
import '../models/technicians/update_technician_request.dart';

class ProfileRepository {
  final ApiClient api;

  ProfileRepository(this.api);

  Future<CustomerProfile> getCustomerProfile() async {
    final response = await api.dio.get("/customers/profile");
    return CustomerProfile.fromJson(response.data['data']);
  }

  Future<TechnicianProfile> getTechnicianProfile() async {
    final response = await api.dio.get("/technicians/profile");
    return TechnicianProfile.fromJson(response.data['data']);
  }

  Future<void> updateCustomerProfile(UpdateCustomerRequest req) async {
    await api.dio.patch("/customers/profile", data: req.toJson());
  }

  Future<void> updateTechnicianProfile(TechnicianProfileRequest req) async {
    await api.dio.patch("/technicians/profile", data: req.toJson());
  }

  Future<void> updateTechnicianProvinces(List<int> provinceIds) async {
    await api.dio.patch(
      "/technicians/provinces",
      data: {"province_ids": provinceIds},
    );
  }
}
