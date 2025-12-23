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

    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint/me/profile');

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

  Future<bool> createAddress({
    required String token,
    required String houseNumber,
    required String subDistrict,
    required String district,
    required String province,
    required String postCode,
    bool isPrimary = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/customers/me/addresses');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "house_number": houseNumber,
        "sub_district": subDistrict,
        "district": district,
        "province": province,
        "zip_code": postCode,
        "is_primary": isPrimary,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('❌ Create Address Failed: ${response.body}');
      return false;
    }
  }

  Future<bool> updateAddress({
    required String token,
    required int addressId,
    required String houseNumber,
    required String subDistrict,
    required String district,
    required String province,
    required String postCode,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/me/addresses/$addressId',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "house_number": houseNumber,
        "sub_district": subDistrict,
        "district": district,
        "province": province,
        "zip_code": postCode,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ Update Address Failed: ${response.body}');
      return false;
    }
  }

  Future<bool> deleteAddress({
    required String token,
    required int addressId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/me/addresses/$addressId',
    );

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      print('❌ Delete Address Failed: ${response.body}');
      return false;
    }
  }
}
