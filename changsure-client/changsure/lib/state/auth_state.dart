import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthState extends ChangeNotifier {
  final storage = const FlutterSecureStorage();

  String? token;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> loadToken() async {
    token = await storage.read(key: "token");
    notifyListeners();
  }

  Future<void> setToken(String newToken) async {
    token = newToken;
    await storage.write(key: "token", value: newToken);
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    await storage.delete(key: "token");
    notifyListeners();
  }
}
