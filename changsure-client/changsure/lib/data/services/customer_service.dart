import 'dart:convert';
import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/models/address_model.dart';
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
    int customerId,
    UserRole role,
    Map<String, dynamic> updates,
  ) async {
    final endpoint = _getEndpoint(role);

    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint/$customerId');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Update customer failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<List<AddressModel>> getAddresses({
    required String token,
    required int customerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/customers/$customerId/addresses'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final List<dynamic> list = json['data'];
          return list.map((e) => AddressModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print("❌ Error fetching addresses: $e");
    }
    return [];
  }

  Future<bool> createAddress({
    required String token,
    required int customerId,
    String? label,
    String? phoneNumber,
    bool? isPrimary,
    String? addressLine,
    String? houseNumber,
    String? village,
    String? moo,
    String? soi,
    String? road,
    required int provinceId,
    required int districtId,
    required int subDistrictId,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/$customerId/addresses',
    );
    try {
      final Map<String, dynamic> body = {
        'province_id': provinceId,
        'district_id': districtId,
        'sub_district_id': subDistrictId,
        'latitude': lat,
        'longitude': lng,
      };
      if (label != null) body['label'] = label;
      if (phoneNumber != null) {
        final p = phoneNumber.trim();
        if (p.isNotEmpty) body['phone_number'] = p;
      }
      if (isPrimary != null) body['is_primary'] = isPrimary;
      if (addressLine != null) body['address_line'] = addressLine;
      if (houseNumber != null) body['house_number'] = houseNumber;
      if (village != null) body['village'] = village;
      if (moo != null) body['moo'] = moo;
      if (soi != null) body['soi'] = soi;
      if (road != null) body['road'] = road;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print(
          '❌ Create Address Error: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print("❌ Exception creating address: $e");
      return false;
    }
  }

  Future<bool> updateAddress({
    required String token,
    required int customerId,
    required int addressId,
    String? label,
    String? phoneNumber,
    bool? isPrimary,
    String? addressLine,
    String? houseNumber,
    String? village,
    String? moo,
    String? soi,
    String? road,
    int? provinceId,
    int? districtId,
    int? subDistrictId,
    double? lat,
    double? lng,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/$customerId/addresses/$addressId',
    );
    try {
      final Map<String, dynamic> body = {};
      if (label != null) body['label'] = label;
      if (phoneNumber != null) {
        final p = phoneNumber.trim();
        body['phone_number'] = p.isEmpty ? null : p;
      }
      if (isPrimary != null) body['is_primary'] = isPrimary;
      if (addressLine != null) body['address_line'] = addressLine;
      if (houseNumber != null) body['house_number'] = houseNumber;
      if (village != null) body['village'] = village;
      if (moo != null) body['moo'] = moo;
      if (soi != null) body['soi'] = soi;
      if (road != null) body['road'] = road;
      if (provinceId != null) body['province_id'] = provinceId;
      if (districtId != null) body['district_id'] = districtId;
      if (subDistrictId != null) body['sub_district_id'] = subDistrictId;
      if (lat != null) body['latitude'] = lat;
      if (lng != null) body['longitude'] = lng;

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          '❌ Update Address Error: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print("❌ Exception updating address: $e");
      return false;
    }
  }

  Future<bool> setPrimaryAddress({
    required String token,
    required int customerId,
    required int addressId,
    bool isPrimary = true,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/$customerId/addresses/$addressId',
    );
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_primary': isPrimary}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error setting primary address: $e");
      return false;
    }
  }

  Future<bool> deleteAddress({
    required String token,
    required int customerId,
    required int addressId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/customers/$customerId/addresses/$addressId',
    );
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error deleting address: $e");
      return false;
    }
  }
}
