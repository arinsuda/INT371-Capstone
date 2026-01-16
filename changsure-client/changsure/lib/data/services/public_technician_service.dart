import 'dart:convert';
import 'package:changsure/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import 'package:changsure/data/models/technician/public_post_model.dart';
import 'package:changsure/data/models/technician/public_technician_model.dart';

class PublicTechnicianService {
  Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<PublicTechnicianProfile?> getPublicProfile(
    int technicianId, {
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/technicians/$technicianId/profile'),
        headers: _headers(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return PublicTechnicianProfile.fromJson(data['data']);
        }
      }

      // debug เพิ่มนิดนึง
      print(
        '❌ Get Public Profile HTTP ${response.statusCode}: ${response.body}',
      );
      return null;
    } catch (e) {
      print('❌ Get Public Profile Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPublicPosts(
    int technicianId, {
    required String token,
    int page = 1,
    int perPage = 20,
    int? categoryId,
    int? serviceId,
    int? provinceId,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (serviceId != null) 'service_id': serviceId.toString(),
        if (provinceId != null) 'province_id': provinceId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/technicians/$technicianId/posts',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers(token: token));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'posts': (data['data']['items'] as List)
                .map((e) => PublicPost.fromJson(e))
                .toList(),
            'total': data['data']['total'],
            'page': data['data']['page'],
            'per_page': data['data']['per_page'],
          };
        }
      }

      print('❌ Get Public Posts HTTP ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Get Public Posts Error: $e');
      return null;
    }
  }

  Future<PublicPost?> getPublicPost(
    int technicianId,
    int postId, {
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/technicians/$technicianId/posts/$postId',
        ),
        headers: _headers(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return PublicPost.fromJson(data['data']);
        }
      }

      print('❌ Get Public Post HTTP ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Get Public Post Error: $e');
      return null;
    }
  }
}
