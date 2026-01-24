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
    required String addressLine,

    String? phoneNumber,

    required int provinceId,
    required int districtId,
    required int subDistrictId,

    required double lat,
    required double lng,

    String? label,
    bool? isPrimary,
    String? postCode,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/customers/me/addresses');

    final Map<String, dynamic> body = {
      "address_line": addressLine,

      "province_id": provinceId,
      "district_id": districtId,
      "sub_district_id": subDistrictId,

      "latitude": lat,
      "longitude": lng,
    };

    if (label != null) body["label"] = label;
    if (phoneNumber != null) {
      final p = phoneNumber.trim();
      if (p.isNotEmpty) body["phone_number"] = p;
    }
    if (addressLine != null) body["address_line"] = addressLine;

    if (postCode != null) body["postal_code"] = postCode;
    if (isPrimary != null) body["is_primary"] = isPrimary;

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> updateAddress({
    required String token,
    required int addressId,
    String? label,
    String? phoneNumber,
    String? addressLine,
    int? provinceId,
    int? districtId,
    int? subDistrictId,

    double? lat,
    double? lng,

    String? postCode,

    bool? isPrimary,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/me/addresses/$addressId',
    );

    final Map<String, dynamic> body = {};

    if (label != null) body["label"] = label;
    if (phoneNumber != null) {
      final p = phoneNumber.trim();
      body["phone_number"] = p.isEmpty ? null : p;
    }
    if (isPrimary != null) body["is_primary"] = isPrimary;

    if (addressLine != null) body["address_line"] = addressLine;

    if (provinceId != null) body["province_id"] = provinceId;
    if (districtId != null) body["district_id"] = districtId;
    if (subDistrictId != null) body["sub_district_id"] = subDistrictId;

    if (lat != null) body["latitude"] = lat;
    if (lng != null) body["longitude"] = lng;

    if (postCode != null) body["postal_code"] = postCode;

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
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
