import 'dart:convert';

import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/data/models/customer/customer_model.dart';

class AuthService {
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      print('JWT decode error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (body['success'] != true || body['data'] == null) return null;

        final data = body['data'] as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null) return null;

        final payload = _decodeJwtPayload(accessToken);

        return {
          'access_token': accessToken,
          'refresh_token': refreshToken ?? '',
          'user_id': payload?['user_id'] as int? ?? 0,
          'role': payload?['role'] as String? ?? '',
        };
      } else {
        print('Login failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      print('Login Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Refresh token failed: $e');
    }
    return null;
  }

  Future<TechnicianModel?> getTechnicianProfile(
    String token,
    int technicianId,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/technicians/$technicianId');
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

  Future<CustomerModel?> getCustomerProfile(
    String token,
    int customerId,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/customers/$customerId');
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
