import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class GeocodingCacheService {
  final Map<String, LatLng> _cache = {};
  final Duration _cacheExpiry = const Duration(hours: 24);
  final Map<String, DateTime> _cacheTimestamps = {};

  LatLng? get(String address) {
    if (!_cache.containsKey(address)) return null;

    final timestamp = _cacheTimestamps[address];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _cache.remove(address);
      _cacheTimestamps.remove(address);
      return null;
    }

    return _cache[address];
  }

  void set(String address, LatLng coordinates) {
    _cache[address] = coordinates;
    _cacheTimestamps[address] = DateTime.now();
  }

  void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  int get cacheSize => _cache.length;
}

final geocodingCacheProvider = Provider<GeocodingCacheService>((ref) {
  return GeocodingCacheService();
});
