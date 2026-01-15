import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/nominatim_search_service.dart';

// HTTP Client ตัวเดียวใช้ทั้งแอป
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return const GeocodingService();
});

final nominatimServiceProvider = Provider<NominatimSearchService>((ref) {
  return NominatimSearchService(client: ref.watch(httpClientProvider));
});
