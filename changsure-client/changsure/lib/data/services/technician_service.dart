import 'dart:convert';
import 'dart:io';
import 'package:changsure/data/models/address_model.dart';
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

  Future<bool> createPost({
    required String token,
    required String description,
    required int categoryId,
    String? title,
    int? provinceId,
    List<File>? images,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/technicians/me/posts');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['description'] = description;
    request.fields['service_category_id'] = categoryId.toString();

    request.fields['title'] =
        title ??
        (description.length > 20 ? description.substring(0, 20) : description);

    request.fields['post_date'] = DateTime.now().toIso8601String();

    if (images != null) {
      for (var file in images) {
        final mimeTypeData = lookupMimeType(file.path)?.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: mimeTypeData != null
                ? MediaType(mimeTypeData[0], mimeTypeData[1])
                : null,
          ),
        );
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Create Post Error: $e");
      return false;
    }
  }

  Future<PostModel?> getPostById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/technicians/me/posts/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return PostModel.fromJson(json['data']);
        }
      }
    } catch (e) {
      print("❌ Get Post Error: $e");
    }
    return null;
  }

  Future<bool> updatePost({
    required String token,
    required int postId,
    String? title,
    String? description,
    int? categoryId,
    int? provinceId,
    List<File>? newImages,
    List<int>? imageIdsToDelete,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/me/posts/$postId',
    );
    final request = http.MultipartRequest('PUT', url);

    request.headers.addAll({'Authorization': 'Bearer $token'});

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (categoryId != null)
      request.fields['service_category_id'] = categoryId.toString();

    if (imageIdsToDelete != null && imageIdsToDelete.isNotEmpty) {
      // ส่งเป็น "101,102,105" ให้ Backend ไป split เอง
      request.fields['image_ids_to_delete'] = imageIdsToDelete.join(',');
    }

    if (newImages != null) {
      for (var file in newImages) {
        final mimeTypeData = lookupMimeType(file.path)?.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'new_images',
            file.path,
            contentType: mimeTypeData != null
                ? MediaType(mimeTypeData[0], mimeTypeData[1])
                : null,
          ),
        );
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Update Post Error: $e");
      return false;
    }
  }

  Future<bool> deletePost({required String token, required int postId}) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/technicians/me/posts/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("❌ Delete Post Error: $e");
      return false;
    }
  }

  Future<List<AddressModel>> getAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/technicians/me/addresses'),
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
    required String houseNumber,
    required String subDistrict,
    required String district,
    required String province,
    required String postCode,

    int? provinceId,
    int? districtId,
    int? subDistrictId,

    double? lat,
    double? lng,
    bool isPrimary = false,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/technicians/me/addresses');

    try {
      final Map<String, dynamic> body = {
        'house_number': houseNumber,
        'sub_district': subDistrict,
        'district': district,
        'province': province,

        'postal_code': postCode,
        'zip_code': postCode,

        'is_primary': isPrimary,
      };

      if (provinceId != null) body['province_id'] = provinceId;
      if (districtId != null) body['district_id'] = districtId;
      if (subDistrictId != null) body['sub_district_id'] = subDistrictId;

      if (lat != null) {
        body['latitude'] = lat;
        body['lat'] = lat;
      }
      if (lng != null) {
        body['longitude'] = lng;
        body['lng'] = lng;
      }

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
        print('❌ Create Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print("❌ Exception creating address: $e");
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

    int? provinceId,
    int? districtId,
    int? subDistrictId,

    double? lat,
    double? lng,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/me/addresses/$addressId',
    );

    try {
      final Map<String, dynamic> body = {
        'house_number': houseNumber,
        'sub_district': subDistrict,
        'district': district,
        'province': province,

        'postal_code': postCode,
        'zip_code': postCode,
      };

      if (provinceId != null) body['province_id'] = provinceId;
      if (districtId != null) body['district_id'] = districtId;
      if (subDistrictId != null) body['sub_district_id'] = subDistrictId;

      if (lat != null) {
        body['latitude'] = lat;
        body['lat'] = lat;
      }
      if (lng != null) {
        body['longitude'] = lng;
        body['lng'] = lng;
      }

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
        print('❌ Update Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print("❌ Exception updating address: $e");
      return false;
    }
  }

  Future<bool> setPrimaryAddress({
    required String token,
    required int addressId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/me/addresses/$addressId/primary',
    );

    try {
      final response = await http.patch(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error setting primary address: $e");
      return false;
    }
  }

  Future<bool> deleteAddress({
    required String token,
    required int addressId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/me/addresses/$addressId',
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
