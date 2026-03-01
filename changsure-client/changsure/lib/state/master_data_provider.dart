import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/master_data_models.dart';
import '../core/constants/api_constants.dart';
import '../data/models/users/users_model.dart';
import 'user_provider.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class MasterDataService {
  final http.Client _client;

  MasterDataService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _getHeaders(String? token) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token?.isNotEmpty ?? false) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Generic GET ────────────────────────────────────────────────────────────
  // BE บางตัวใช้ "success" (service module) บางตัวใช้ "status":"success" (province/district)
  // ดังนั้น parser รับ body ทั้งก้อนเพื่อให้แต่ละ caller ดึง field เองได้
  Future<T> _get<T>({
    required String endpoint,
    required T Function(Map<String, dynamic> body) parser,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return parser(body);
      }

      throw ApiException(
        'Failed to fetch data from $endpoint',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  // ─── Generic POST ────────────────────────────────────────────────────────────
  Future<T> _post<T>({
    required String endpoint,
    required T Function(dynamic data) parser,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await _client.post(
        uri,
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return parser(json['data']);
      }

      throw ApiException(
        'Failed to post data to $endpoint',
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  // ─── Provinces ───────────────────────────────────────────────────────────────
  // BE: GET /provinces → { "status": "success", "total": N, "data": [...] }
  Future<List<ProvinceModel>> getProvinces(String? token) async {
    return _get(
      endpoint: '/provinces',
      token: token,
      parser: (body) =>
          (body['data'] as List).map((e) => ProvinceModel.fromJson(e)).toList(),
    );
  }

  // ─── Districts ───────────────────────────────────────────────────────────────
  // BE route: GET /provinces/:province_id/districts → { "success": true, "data": [...] }
  // หมายเหตุ: GET /districts?province_id=X ใช้ utils.ParseUintParam ซึ่ง parse path param
  // ไม่ใช่ query param ทำให้ได้ 400 เสมอ → ใช้ nested route แทน
  Future<List<DistrictModel>> getDistricts({
    required String? token,
    required int provinceId,
  }) async {
    return _get(
      endpoint: '/provinces/$provinceId/districts',
      token: token,
      parser: (body) => ((body['data'] ?? []) as List)
          .map((e) => DistrictModel.fromJson(e))
          .toList(),
    );
  }

  // ─── Sub-Districts ───────────────────────────────────────────────────────────
  // BE route: GET /districts/:district_id/sub-districts → { "status": "success", "data": [...] }
  // (ใช้ nested route เหมือน districts เพื่อความสม่ำเสมอ)
  Future<List<SubDistrictModel>> getSubDistricts({
    required String? token,
    required int districtId,
  }) async {
    return _get(
      endpoint: '/districts/$districtId/sub-districts',
      token: token,
      parser: (body) => ((body['data'] ?? []) as List)
          .map((e) => SubDistrictModel.fromJson(e))
          .toList(),
    );
  }

  // ─── Services ────────────────────────────────────────────────────────────────
  // BE: GET /services/all → { "success": true, "total": N, "data": [...] }
  Future<List<ServiceModel>> getAllServices(String? token) async {
    if (token?.trim().isEmpty ?? true) {
      throw ApiException('Authentication token is required');
    }
    return _get(
      endpoint: '/services/all',
      token: token,
      parser: (body) =>
          (body['data'] as List).map((e) => ServiceModel.fromJson(e)).toList(),
    );
  }

  // BE: GET /services?category_id=X → { "success": true, "total": N, "data": [...] }
  Future<List<ServiceModel>> getServicesByCategory(int categoryId) async {
    return _get(
      endpoint: '/services',
      queryParams: {'category_id': categoryId.toString()},
      parser: (body) => ((body['data'] ?? []) as List)
          .map((e) => ServiceModel.fromJson(e))
          .toList(),
    );
  }

  // ─── Service Categories (with services merged) ────────────────────────────────
  // BE: GET /service-categories → { "success": true, "data": [...] }
  // BE: GET /services/all       → { "success": true, "total": N, "data": [...] }
  Future<List<ServiceCategoryModel>> getServiceCategoriesWithServices(
    String? token,
  ) async {
    try {
      final headers = _getHeaders(token);

      final results = await Future.wait([
        _client.get(
          Uri.parse('${ApiConstants.baseUrl}/service-categories'),
          headers: headers,
        ),
        _client.get(
          Uri.parse('${ApiConstants.baseUrl}/services/all'),
          headers: headers,
        ),
      ]);

      final catResponse = results[0];
      final serviceResponse = results[1];

      if (catResponse.statusCode != 200 || serviceResponse.statusCode != 200) {
        throw ApiException(
          'Failed to fetch categories or services',
          catResponse.statusCode,
        );
      }

      final categories = (jsonDecode(catResponse.body)['data'] as List)
          .map((e) => ServiceCategoryModel.fromJson(e))
          .toList();

      final services = (jsonDecode(serviceResponse.body)['data'] as List)
          .map((e) => ServiceModel.fromJson(e))
          .toList();

      return categories
          .map((category) {
            final categoryServices = services
                .where((service) => service.categoryId == category.id)
                .toList();

            return categoryServices.isNotEmpty
                ? category.copyWith(services: categoryServices)
                : null;
          })
          .whereType<ServiceCategoryModel>()
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch categories with services: $e');
    }
  }

  // ─── Technicians ─────────────────────────────────────────────────────────────
  // BE: GET /technicians?service_id=X&province_id=Y
  //     → { "success": true, "data": { "items": [...], ... } }
  Future<List<Technician>> getAllTechnicians({
    required String? token,
    required int serviceId,
    required int provinceId,
  }) async {
    return _get(
      endpoint: '/technicians',
      token: token,
      queryParams: {
        'service_id': serviceId.toString(),
        'province_id': provinceId.toString(),
      },
      parser: (body) => ((body['data']?['items'] ?? []) as List)
          .map((e) => Technician.fromJson(e))
          .toList(),
    );
  }

  // BE: POST /technicians/auto-select → { "success": true, "data": { ... } | null }
  Future<Technician?> getAutoSelectTechnician({
    required String? token,
    required int serviceId,
    required int provinceId,
    int? minPrice,
    int? maxPrice,
  }) async {
    final body = <String, dynamic>{
      'service_id': serviceId,
      'province_id': provinceId,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };

    return _post(
      endpoint: '/technicians/auto-select',
      token: token,
      body: body,
      parser: (data) => data != null ? Technician.fromJson(data) : null,
    );
  }

  // ─── Register ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> register(RegisterModel model) async {
    return _post<Map<String, dynamic>?>(
      endpoint: '/auth/register',
      body: model.toJson(),
      parser: (data) => data,
    );
  }

  void dispose() {
    _client.close();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final masterDataServiceProvider = Provider((ref) {
  final service = MasterDataService();
  ref.onDispose(service.dispose);
  return service;
});

final tokenProvider = Provider<String?>(
  (ref) => ref.watch(userProvider.select((u) => u?.token?.trim())),
);

final provincesProvider = FutureProvider<List<ProvinceModel>>((ref) async {
  final token = ref.watch(tokenProvider);
  return ref.read(masterDataServiceProvider).getProvinces(token);
});

class RegisterNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<void> register(RegisterModel model) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(masterDataServiceProvider);
      final result = await service.register(model);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final registerProvider =
    AsyncNotifierProvider<RegisterNotifier, Map<String, dynamic>?>(
      RegisterNotifier.new,
    );

final districtsProvider = FutureProvider.family<List<DistrictModel>, int>((
  ref,
  provinceId,
) async {
  final token = ref.watch(tokenProvider);
  return ref
      .read(masterDataServiceProvider)
      .getDistricts(token: token, provinceId: provinceId);
});

final subDistrictsProvider = FutureProvider.family<List<SubDistrictModel>, int>(
  (ref, districtId) async {
    final token = ref.watch(tokenProvider);
    return ref
        .read(masterDataServiceProvider)
        .getSubDistricts(token: token, districtId: districtId);
  },
);

final allServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null || token.isEmpty) return [];
  return ref.read(masterDataServiceProvider).getAllServices(token);
});

final serviceCategoriesProvider = FutureProvider<List<ServiceCategoryModel>>((
  ref,
) async {
  final token = ref.watch(tokenProvider);
  if (token == null || token.isEmpty) return [];
  return ref
      .read(masterDataServiceProvider)
      .getServiceCategoriesWithServices(token);
});

final servicesByCategoryProvider =
    FutureProvider.family<List<ServiceModel>, int>((ref, categoryId) async {
      return ref
          .read(masterDataServiceProvider)
          .getServicesByCategory(categoryId);
    });

final allTechniciansProvider =
    FutureProvider.family<List<Technician>, TechnicianQuery>((
      ref,
      query,
    ) async {
      final token = ref.watch(tokenProvider);
      return ref
          .read(masterDataServiceProvider)
          .getAllTechnicians(
            token: token,
            serviceId: query.serviceId,
            provinceId: query.provinceId,
          );
    });

final autoSelectTechnicianProvider =
    FutureProvider.family<Technician?, AutoSelectTechnicianQuery>((
      ref,
      query,
    ) async {
      final token = ref.watch(tokenProvider);
      return ref
          .read(masterDataServiceProvider)
          .getAutoSelectTechnician(
            token: token,
            serviceId: query.serviceId,
            provinceId: query.provinceId,
            minPrice: query.minPrice,
            maxPrice: query.maxPrice,
          );
    });
