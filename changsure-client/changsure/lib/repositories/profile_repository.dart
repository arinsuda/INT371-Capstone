import '../api/api_client.dart';
import '../models/customers/customer_profile.dart';
import '../models/technicians/technician_profile.dart';

class ProfileRepository {
  final ApiClient client;

  ProfileRepository(this.client);

  Future<CustomerProfile> getCustomerProfile() async {
    final res = await client.dio.get("/customers/profile");
    return CustomerProfile.fromJson(res.data["data"]);
  }

  Future<TechnicianProfile> getTechnicianProfile() async {
    final res = await client.dio.get("/technicians/profile");
    return TechnicianProfile.fromJson(res.data["data"]);
  }
}
