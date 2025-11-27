import '../api/api_client.dart';
import '../models/customers/customer_profile.dart';
import '../models/technicians/technician_profile.dart';

class ProfileRepository {
  final ApiClient api;

  ProfileRepository(this.api);

  Future<CustomerProfile> getCustomerProfile() async {
    final response = await api.dio.get("/customers/profile");
    return CustomerProfile.fromJson(response.data['data']);
  }

  Future<TechnicianProfile> getTechnicianProfile() async {
    final response = await api.dio.get("/technicians/profile");
    return TechnicianProfile.fromJson(response.data);
  }
}
