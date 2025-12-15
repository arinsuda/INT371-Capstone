import 'dart:convert';

import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/data/models/customer/customer_model.dart';

class AuthService {
  Future<UserModel?> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'];

        final String accessToken = data['access_token'];

        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        final String roleStr = decodedToken['role'] ?? 'guest';

        print("Decoded Role: $roleStr");
        if (roleStr == 'technician') {
          final techProfile = await getTechnicianProfile(accessToken);
          if (techProfile != null) {
            return UserModel(
              role: UserRole.technician,
              token: accessToken,
              technicianProfile: techProfile,
            );
          }
        } else if (roleStr == 'customer') {
          final customerProfile = await getCustomerProfile(accessToken);
          if (customerProfile != null) {
            return UserModel(
              role: UserRole.customer,
              token: accessToken,
              customerProfile: customerProfile,
            );
          }
        }
      } else {
        print('Login Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Login Error: $e');
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
