import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/master_data_models.dart';
import '../core/constants/api_constants.dart';
import 'user_provider.dart';

class MasterDataService {
  Map<String, String> _getHeaders(String? token) {
    if (token != null && token.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<List<ProvinceModel>> getProvinces(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/provinces'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => ProvinceModel.fromJson(e)).toList();
      } else {
        print("Province Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching provinces: $e");
    }
    return [];
  }

  Future<List<DistrictModel>> getDistricts(
    String? token,
    int provinceId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/districts?province_id=$provinceId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        return data.map((e) => DistrictModel.fromJson(e)).toList();
      } else {
        print("District Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching districts: $e");
    }
    return [];
  }

  Future<List<SubDistrictModel>> getSubDistricts(
    String? token,
    int districtId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/sub-districts?district_id=$districtId',
        ),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        return data.map((e) => SubDistrictModel.fromJson(e)).toList();
      } else {
        print("SubDistrict Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sub-districts: $e");
    }
    return [];
  }

  Future<List<ServiceCategoryModel>> getServiceCategoriesWithServices(
    String? token,
  ) async {
    try {
      final headers = _getHeaders(token);

      final catResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/service-categories'),
        headers: headers,
      );

      final serviceResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/services/all'),
        headers: headers,
      );

      if (catResponse.statusCode == 200 && serviceResponse.statusCode == 200) {
        final catList = (jsonDecode(catResponse.body)['data'] as List)
            .map((e) => ServiceCategoryModel.fromJson(e))
            .toList();

        final serviceList = (jsonDecode(serviceResponse.body)['data'] as List)
            .map((e) => ServiceModel.fromJson(e))
            .toList();

        List<ServiceCategoryModel> result = [];
        for (var cat in catList) {
          final matchingServices = serviceList
              .where((s) => s.categoryId == cat.id)
              .toList();

          if (matchingServices.isNotEmpty) {
            result.add(cat.copyWith(services: matchingServices));
          } else {}
        }
        return result;
      } else {
        print(
          "Service API Error: Cat=${catResponse.statusCode}, Ser=${serviceResponse.statusCode}",
        );
      }
    } catch (e) {
      print("Error fetching categories/services: $e");
    }
    return [];
  }

  Future<List<ServiceModel>> getServicesByCategory(int categoryId) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/services?category_id=$categoryId'),
    );

    final body = jsonDecode(res.body);
    final List list = body['data'] ?? [];

    return list.map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<List<Technician>> getAllTechnician(
    String? token,
    int serviceId,
    int provinceId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/technicians'
        '?service_id=$serviceId&province_id=$provinceId',
      ),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode})');
    }

    final json = jsonDecode(response.body);
    final List items = json['data']?['items'] ?? [];

    return items.map((e) => Technician.fromJson(e)).toList();
  }

  Future<Technician?> getAutoSelectTechnician(
    String? token,
    int serviceId,
    int provinceId, {
    int? minPrice,
    int? maxPrice,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/technicians/auto-select'),
      headers: {..._getHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        "service_id": serviceId,
        "province_id": provinceId,
        if (minPrice != null) "min_price": minPrice,
        if (maxPrice != null) "max_price": maxPrice,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Auto select failed');
    }

    final json = jsonDecode(response.body);
    final data = json['data'];

    if (data == null) return null;

    return Technician.fromJson(data);
  }
}

final masterDataServiceProvider = Provider((ref) => MasterDataService());

final provincesProvider = FutureProvider<List<ProvinceModel>>((ref) async {
  final user = ref.watch(userProvider);
  return ref.read(masterDataServiceProvider).getProvinces(user?.token);
});

final districtsProvider = FutureProvider.family<List<DistrictModel>, int>((
  ref,
  provinceId,
) async {
  final user = ref.watch(userProvider);
  return ref
      .read(masterDataServiceProvider)
      .getDistricts(user?.token, provinceId);
});

final subDistrictsProvider = FutureProvider.family<List<SubDistrictModel>, int>(
  (ref, districtId) async {
    final user = ref.watch(userProvider);
    return ref
        .read(masterDataServiceProvider)
        .getSubDistricts(user?.token, districtId);
  },
);

final serviceCategoriesProvider = FutureProvider<List<ServiceCategoryModel>>((
  ref,
) async {
  final user = ref.watch(userProvider);
  return ref
      .read(masterDataServiceProvider)
      .getServiceCategoriesWithServices(user?.token);
});

final allTechnicianProvider =
    FutureProvider.family<List<Technician>, TechnicianQuery>((
      ref,
      query,
    ) async {
      final user = ref.watch(userProvider);

      return ref
          .read(masterDataServiceProvider)
          .getAllTechnician(user?.token, query.serviceId, query.provinceId);
    });

final servicesByCategoryProvider =
    FutureProvider.family<List<ServiceModel>, int>((ref, categoryId) async {
      return ref
          .read(masterDataServiceProvider)
          .getServicesByCategory(categoryId);
    });

final autoSelectTechnicianProvider =
    FutureProvider.family<Technician?, AutoSelectTechnicianQuery>((
      ref,
      query,
    ) async {
      final user = ref.watch(userProvider);

      return ref
          .read(masterDataServiceProvider)
          .getAutoSelectTechnician(
            user?.token,
            query.serviceId,
            query.provinceId,
            minPrice: query.minPrice,
            maxPrice: query.maxPrice,
          );
    });
