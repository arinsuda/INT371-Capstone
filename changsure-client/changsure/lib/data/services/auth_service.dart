import 'dart:convert';

import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/data/models/customer/customer_model.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Login failed: ${response.body}");
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Refresh token failed: $e");
    }
    return null;
  }

  Future<TechnicianModel?> getTechnicianProfile(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/technicians/me/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return TechnicianModel.fromJson(jsonResponse['data']);
      }
    } catch (e) {
      print('Get Tech Profile Error: $e');
    }
    return null;
  }

  Future<CustomerModel?> getCustomerProfile(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/customers/me/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return CustomerModel.fromJson(jsonResponse['data']);
      }
    } catch (e) {
      print('Get Customer Profile Error: $e');
    }
    return null;
  }
}
