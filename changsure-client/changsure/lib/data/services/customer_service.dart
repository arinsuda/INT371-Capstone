import 'dart:convert';
import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import 'package:changsure/data/models/users/users_model.dart';
import '../models/customer/customer_model.dart';

class CustomerService {
  String _getEndpoint(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customers';
      case UserRole.technician:
        return 'technicians';
      default:
        throw Exception('Unsupported user role');
    }
  }

  Future<bool> updateCustomer(
      String token,
      UserRole role,
      CustomerModel customer,
      ) async {
    final endpoint = _getEndpoint(role);

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/$endpoint/me/profile',
    );

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(customer.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Update customer failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
