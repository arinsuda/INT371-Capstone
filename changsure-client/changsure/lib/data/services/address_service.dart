import 'dart:convert';
import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import 'package:changsure/data/models/address_model.dart';
import 'package:changsure/data/models/users/users_model.dart';

class AddressService {
  String _getEndpoint(UserRole role) {
    return role == UserRole.technician ? 'technicians' : 'customers';
  }

  Future<List<AddressModel>> getAddresses(String token, UserRole role) async {
    final endpoint = _getEndpoint(role);
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint/me/addresses');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'] ?? [];
      return data.map((e) => AddressModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load addresses: ${response.statusCode}');
    }
  }

  Future<bool> createAddress(
    String token,
    UserRole role,
    AddressModel address,
  ) async {
    final endpoint = _getEndpoint(role);
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint/me/addresses');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(address.toJson()),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateAddress(
    String token,
    UserRole role,
    AddressModel address,
  ) async {
    final endpoint = _getEndpoint(role);
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/$endpoint/me/addresses/${address.id}',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(address.toJson()),
    );

    return response.statusCode == 200;
  }
}
