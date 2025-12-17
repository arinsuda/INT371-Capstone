import 'dart:convert';
import 'dart:io';
import 'package:changsure/data/models/technician/post_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:changsure/core/constants/api_constants.dart';

class TechnicianService {
  Future<bool> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
    required String phone,
    String? bio,
    List<int>? provinceIds,
    List<Map<String, dynamic>>? services,
    File? avatarFile,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/technicians/me/profile');

    final request = http.MultipartRequest('PATCH', url);

    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['firstname'] = firstName;
    request.fields['lastname'] = lastName;
    request.fields['phone'] = phone;
    if (bio != null) {
      request.fields['bio'] = bio;
    }

    if (provinceIds != null) {
      request.fields['province_ids'] = jsonEncode(provinceIds);
    }

    if (services != null) {
      request.fields['services'] = jsonEncode(services);
    }

    if (avatarFile != null) {
      final mimeTypeData = lookupMimeType(avatarFile.path)?.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: mimeTypeData != null
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : null,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("✅ Update Technician Profile Success");
        return true;
      } else {
        print("❌ Update Failed: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error calling update profile: $e");
      return false;
    }
  }

  Future<List<PostModel>> getMyPosts(String token, {int? categoryId}) async {
    try {
      Map<String, String> queryParams = {};
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/technicians/me/posts',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true && json['data'] != null) {
          final List<dynamic> items = json['data']['items'] ?? [];

          return items.map((e) => PostModel.fromJson(e)).toList();
        }
      } else {
        print("❌ Get Posts Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching posts: $e");
    }

    return [];
  }
}
