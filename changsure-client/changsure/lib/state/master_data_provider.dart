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
        Uri.parse('${ApiConstants.baseUrl}/services?page=1&page_size=1000'),
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
}

final masterDataServiceProvider = Provider((ref) => MasterDataService());

final provincesProvider = FutureProvider<List<ProvinceModel>>((ref) async {
  final user = ref.watch(userProvider);
  return ref.read(masterDataServiceProvider).getProvinces(user?.token);
});

final serviceCategoriesProvider = FutureProvider<List<ServiceCategoryModel>>((
  ref,
) async {
  final user = ref.watch(userProvider);
  return ref
      .read(masterDataServiceProvider)
      .getServiceCategoriesWithServices(user?.token);
});
