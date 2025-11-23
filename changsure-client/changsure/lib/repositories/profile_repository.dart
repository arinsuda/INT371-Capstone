import '../api/api_client.dart';
import '../models/profile.dart';

class ProfileRepository {
  final ApiClient client;
  ProfileRepository(this.client);

  Future<Profile> getProfile() async {
    final res = await client.dio.get("/customers/profile");

    final body = res.data as Map<String, dynamic>;
    if (body["success"] != true) {
      throw Exception(body["message"] ?? "Load profile failed");
    }

    final dataJson = body["data"] as Map<String, dynamic>;
    return Profile.fromJson(dataJson);
  }
}
