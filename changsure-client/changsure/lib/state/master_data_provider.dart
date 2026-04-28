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
        final data = json is Map<String, dynamic> ? json['data'] : json;

        return parser(data);
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

  Future<List<ProvinceModel>> getProvinces(String? token) async {
    return _get(
      endpoint: '/provinces',
      token: token,
      parser: (body) =>
          (body['data'] as List).map((e) => ProvinceModel.fromJson(e)).toList(),
    );
  }

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

  Future<Map<String, dynamic>?> createCustomerAddress({
    required String? token,
    required int customerId,
    required Map<String, dynamic> body,
  }) async {
    if (token?.isEmpty ?? true) {
      throw ApiException('Authentication token is required');
    }

    return _post<Map<String, dynamic>?>(
      endpoint: '/customers/$customerId/addresses',

      token: token,
      body: body,
      parser: (data) => data,
    );
  }

  Future<Map<String, dynamic>?> createTechnicianAddress({
    required String? token,
    required int technicianId,
    required Map<String, dynamic> body,
  }) async {
    if (token?.isEmpty ?? true) {
      throw ApiException('Authentication token is required');
    }

    return _post<Map<String, dynamic>?>(
      endpoint: '/technicians/$technicianId/addresses',

      token: token,
      body: body,
      parser: (data) => data,
    );
  }

  Future<ServiceModel> getServiceMenuDetail({
    required int serviceId,
    required int provinceId,
  }) async {
    return _get(
      endpoint: '/services/menu/$serviceId',
      queryParams: {'province_id': provinceId.toString()},
      parser: (body) => ServiceModel.fromJson(body['data']),
    );
  }

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

  Future<List<ServiceModel>> getServicesByCategory(int categoryId) async {
    return _get(
      endpoint: '/services',
      queryParams: {'category_id': categoryId.toString()},
      parser: (body) => ((body['data'] ?? []) as List)
          .map((e) => ServiceModel.fromJson(e))
          .toList(),
    );
  }

  Future<List<ServiceCategoryModel>> getServiceCategoriesOnly() async {
    return _get(
      endpoint: '/service-categories',
      parser: (body) => ((body['data'] ?? []) as List)
          .map((e) => ServiceCategoryModel.fromJson(e))
          .toList(),
    );
  }

  Future<List<ServiceCategoryModel>> getServiceCategoriesWithServices({
    required int provinceId,
  }) async {
    return _get(
      endpoint: '/services/menu',
      queryParams: {'province_id': provinceId.toString()},
      parser: (body) => ((body['data'] ?? []) as List)
          .map((e) => ServiceCategoryModel.fromJson(e))
          .toList(),
    );
  }

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

  Future<Map<String, dynamic>?> registerCustomer(CustomerRegisterModel model) {
    return _post(
      endpoint: '/auth/customer/register',
      body: model.toJson(),
      parser: (data) => data,
    );
  }

  Future<Map<String, dynamic>?> registerTechnician(
    TechnicianRegisterModel model,
  ) {
    return _post(
      endpoint: '/auth/technician/register',
      body: model.toJson(),
      parser: (data) => data,
    );
  }

  void dispose() {
    _client.close();
  }

  Future<DocumentTermResponse> getDocumentService() {
    return _get(
      endpoint: '/documents/changsure-terms',
      queryParams: {'locale': 'th'},
      parser: (body) => DocumentTermResponse.fromJson(body),
    );
  }

  Future<DocumentAcceptanceResponse> acceptDocument({
    required String slug,
    required String token,
    required DocumentAcceptanceRequest request,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/documents/$slug/acceptances?locale=th',
    );

    final response = await _client.post(
      uri,
      headers: _getHeaders(token),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return DocumentAcceptanceResponse.fromJson(json);
    }

    throw ApiException('Failed to accept document', response.statusCode);
  }
}

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

class CustomerRegisterNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<void> register(CustomerRegisterModel model) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(masterDataServiceProvider);
      final result = await service.registerCustomer(model);
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final customerRegisterProvider =
    AsyncNotifierProvider<CustomerRegisterNotifier, Map<String, dynamic>?>(
      CustomerRegisterNotifier.new,
    );

class TechnicianRegisterNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<Map<String, dynamic>?> register(TechnicianRegisterModel model) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(masterDataServiceProvider);
      final result = await service.registerTechnician(model);

      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final technicianRegisterProvider =
    AsyncNotifierProvider<TechnicianRegisterNotifier, Map<String, dynamic>?>(
      TechnicianRegisterNotifier.new,
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
  return ref.read(masterDataServiceProvider).getServiceCategoriesOnly();
});

final serviceMenuProvider =
    FutureProvider.family<List<ServiceCategoryModel>, int>((
      ref,
      provinceId,
    ) async {
      return ref
          .read(masterDataServiceProvider)
          .getServiceCategoriesWithServices(provinceId: provinceId);
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

class AddressNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createCustomerAddress(Map<String, dynamic> body) async {
    try {
      final user = ref.read(userProvider);

      if (user == null || !user.isAuthenticated) {
        throw Exception("User not authenticated");
      }

      final service = ref.read(masterDataServiceProvider);

      await service.createCustomerAddress(
        token: user.token,
        customerId: user.id,
        body: body,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createTechnicianAddress(Map<String, dynamic> body) async {
    try {
      final user = ref.read(userProvider);

      if (user == null || !user.isAuthenticated) {
        throw Exception("User not authenticated");
      }

      final service = ref.read(masterDataServiceProvider);

      await service.createTechnicianAddress(
        token: user.token,
        technicianId: user.id,
        body: body,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}

final addressProvider = AsyncNotifierProvider<AddressNotifier, void>(
  AddressNotifier.new,
);

final documentProvider = FutureProvider<DocumentTermResponse>((ref) async {
  print("📄 CALL DOCUMENT PROVIDER");

  final user = ref.read(userProvider);
  final service = ref.read(masterDataServiceProvider);

  return service.getDocumentService();
});

final documentAcceptanceProvider =
    FutureProvider.family<
      DocumentAcceptanceResponse,
      DocumentAcceptanceRequest
    >((ref, request) async {
      final user = ref.read(userProvider);
      final service = ref.read(masterDataServiceProvider);

      if (user == null || user.token == null) {
        throw ApiException("Token not found");
      }

      return service.acceptDocument(
        slug: "changsure-terms",
        token: user.token!,
        request: request,
      );
    });

class ServiceMenuDetailQuery {
  final int serviceId;
  final int provinceId;

  const ServiceMenuDetailQuery({
    required this.serviceId,
    required this.provinceId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMenuDetailQuery &&
          serviceId == other.serviceId &&
          provinceId == other.provinceId;

  @override
  int get hashCode => serviceId.hashCode ^ provinceId.hashCode;
}

final serviceMenuDetailProvider =
    FutureProvider.family<ServiceModel, ServiceMenuDetailQuery>((
      ref,
      query,
    ) async {
      return ref
          .read(masterDataServiceProvider)
          .getServiceMenuDetail(
            serviceId: query.serviceId,
            provinceId: query.provinceId,
          );
    });
