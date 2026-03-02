import 'dart:convert';
import 'dart:io';
import 'package:changsure/data/models/address_model.dart';
import 'package:changsure/data/models/technician/post_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:changsure/core/constants/api_constants.dart';

class TechnicianService {
  Future<TechnicianModel?> getProfile({
    required String token,
    required int technicianId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/technicians/$technicianId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return TechnicianModel.fromJson(json['data']);
        }
      } else {
        print('❌ Get Profile Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Profile Error: $e');
    }
    return null;
  }

  Future<bool> updateProfile({
    required String token,
    required int technicianId,
    required String firstName,
    required String lastName,
    required String phone,
    String? bio,
    List<int>? provinceIds,
    List<Map<String, dynamic>>? services,
    File? avatarFile,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/technicians/$technicianId');
    final request = http.MultipartRequest('PATCH', url);
    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['firstname'] = firstName;
    request.fields['lastname'] = lastName;
    request.fields['phone'] = phone;
    if (bio != null) request.fields['bio'] = bio;
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
        print('✅ Update Technician Profile Success');
        return true;
      } else {
        print('❌ Update Failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error calling update profile: $e');
      return false;
    }
  }

  Future<bool> updateProvinces({
    required String token,
    required int technicianId,
    required List<int> provinceIds,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/$technicianId/provinces',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'province_ids': provinceIds}),
      );
      if (response.statusCode == 200) {
        print('✅ Update Provinces Success');
        return true;
      } else {
        print('❌ Update Provinces Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating provinces: $e');
      return false;
    }
  }

  Future<bool> uploadAvatar({
    required String token,
    required int technicianId,
    required File avatarFile,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/$technicianId/avatar',
    );
    final request = http.MultipartRequest('PATCH', url);
    request.headers.addAll({'Authorization': 'Bearer $token'});

    final mimeTypeData = lookupMimeType(avatarFile.path)?.split('/');
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        avatarFile.path,
        contentType: mimeTypeData != null
            ? MediaType(mimeTypeData[0], mimeTypeData[1])
            : null,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        print('✅ Upload Avatar Success');
        return true;
      } else {
        print('❌ Upload Avatar Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPosts({
    required String token,
    required int technicianId,
    int? categoryId,
    int? serviceId,
    int? provinceId,
    String? search,
    bool? isPublished,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (categoryId != null)
        queryParams['category_id'] = categoryId.toString();
      if (serviceId != null) queryParams['service_id'] = serviceId.toString();
      if (provinceId != null)
        queryParams['province_id'] = provinceId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isPublished != null) {
        queryParams['is_published'] = isPublished.toString();
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/technicians/$technicianId/posts',
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
          final data = json['data'] as Map<String, dynamic>;

          final List<dynamic> items = data['items'] ?? [];
          final int total = (data['total'] as num?)?.toInt() ?? items.length;
          return {
            'posts': items
                .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
                .toList(),
            'total': total,
          };
        }
      } else {
        print('❌ Get Posts Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching posts: $e');
    }
    return null;
  }

  Future<PostModel?> getPostById({
    required String token,
    required int technicianId,
    required int postId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/technicians/$technicianId/posts/$postId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return PostModel.fromJson(json['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('❌ Get Post Error: $e');
    }
    return null;
  }

  Future<bool> createPost({
    required String token,
    required int technicianId,
    required String title,
    String? description,
    int? categoryId,
    List<File>? images,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/$technicianId/posts',
    );
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll({'Authorization': 'Bearer $token'});

    request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (categoryId != null) {
      request.fields['service_category_id'] = categoryId.toString();
    }
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Create Post Success');
        return true;
      } else {
        print(
          '❌ Create Post Failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Create Post Error: $e');
      return false;
    }
  }

  Future<bool> updatePost({
    required String token,
    required int technicianId,
    required int postId,
    String? title,
    String? description,
    int? categoryId,
    bool? isPublished,
    List<File>? newImages,
    List<int>? imageIdsToDelete,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/$technicianId/posts/$postId',
    );
    final request = http.MultipartRequest('PUT', url);
    request.headers.addAll({'Authorization': 'Bearer $token'});

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (categoryId != null) {
      request.fields['service_category_id'] = categoryId.toString();
    }
    if (isPublished != null) {
      request.fields['is_published'] = isPublished.toString();
    }
    if (imageIdsToDelete != null && imageIdsToDelete.isNotEmpty) {
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Update Post Success');
        return true;
      } else {
        print(
          '❌ Update Post Failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Update Post Error: $e');
      return false;
    }
  }

  Future<bool> deletePost({
    required String token,
    required int technicianId,
    required int postId,
    bool hard = false,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/technicians/$technicianId/posts/$postId',
      ).replace(queryParameters: hard ? {'hard': 'true'} : null);

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Delete Post Error: $e');
      return false;
    }
  }

  Future<List<AddressModel>> getAddresses({
    required String token,
    required int technicianId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/technicians/$technicianId/addresses',
        ),
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
      print('❌ Error fetching addresses: $e');
    }
    return [];
  }

  Future<bool> createAddress({
    required String token,
    required int technicianId,
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
      '${ApiConstants.baseUrl}/technicians/$technicianId/addresses',
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
      print('❌ Exception creating address: $e');
      return false;
    }
  }

  Future<bool> updateAddress({
    required String token,
    required int technicianId,
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
      '${ApiConstants.baseUrl}/technicians/$technicianId/addresses/$addressId',
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
      print('❌ Exception updating address: $e');
      return false;
    }
  }

  Future<bool> setPrimaryAddress({
    required String token,
    required int technicianId,
    required int addressId,
    bool isPrimary = true,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/$technicianId/addresses/$addressId',
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
      print('❌ Error setting primary address: $e');
      return false;
    }
  }

  Future<bool> deleteAddress({
    required String token,
    required int technicianId,
    required int addressId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/technicians/$technicianId/addresses/$addressId',
    );
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error deleting address: $e');
      return false;
    }
  }
}
