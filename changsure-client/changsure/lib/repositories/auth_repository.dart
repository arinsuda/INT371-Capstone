import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  final ApiClient client;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this.client);

  Future<LoginResponse> login(LoginRequest req) async {
    final res = await client.dio.post("/auth/login", data: req.toJson());

    final body = res.data as Map<String, dynamic>;

    if (body["success"] != true) {
      throw Exception(body["message"] ?? "Login failed");
    }

    final dataJson = body["data"] as Map<String, dynamic>;
    final data = LoginResponse.fromJson(dataJson);

    await _storage.write(key: "token", value: data.accessToken);

    await _storage.write(key: "refresh_token", value: data.refreshToken);

    return data;
  }
}
