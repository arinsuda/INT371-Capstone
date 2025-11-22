import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  final ApiClient client;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this.client);

  Future<LoginResponse> login(LoginRequest req) async {
    final res = await client.dio.post("/api/login", data: req.toJson());
    final data = LoginResponse.fromJson(res.data);

    // เก็บ token
    await _storage.write(key: "token", value: data.token);
    return data;
  }
}
