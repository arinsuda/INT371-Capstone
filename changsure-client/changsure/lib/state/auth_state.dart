import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthState extends ChangeNotifier {
  final storage = const FlutterSecureStorage();

  String? token;
  String? role;

  bool get isLoggedIn => token != null && token!.isNotEmpty;
  bool get isCustomer => role == 'customer';
  bool get isTechnician => role == 'technician';

  Future<void> loadToken() async {
    final storedToken = await storage.read(key: "token");
    _applyToken(storedToken);
  }

  Future<void> setToken(String newToken) async {
    await storage.write(key: "token", value: newToken);
    _applyToken(newToken);
  }

  Future<void> logout() async {
    token = null;
    role = null;
    await storage.delete(key: "token");
    notifyListeners();
  }

  void _applyToken(String? newToken) {
    token = newToken;
    role = null;

    if (newToken != null && newToken.isNotEmpty) {
      try {
        final decoded = JwtDecoder.decode(newToken);

        role =
            decoded["role"] as String? ??
            decoded["user_type"] as String? ??
            decoded["type"] as String?;
      } catch (_) {
        role = null;
      }
    }

    notifyListeners();
  }
}
