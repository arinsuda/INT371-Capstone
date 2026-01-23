import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  const GeocodingService();

  Future<LatLng?> locationFromAddress(String query) async {
    try {
      final locs = await geo.locationFromAddress(query);
      if (locs.isEmpty) return null;
      return LatLng(locs.first.latitude, locs.first.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<String> reversePretty(LatLng p) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );
      if (placemarks.isEmpty) return '';

      final pm = placemarks.first;
      final parts = <String>[
        if ((pm.name ?? '').trim().isNotEmpty) pm.name!.trim(),
        if ((pm.subLocality ?? '').trim().isNotEmpty) pm.subLocality!.trim(),
        if ((pm.locality ?? '').trim().isNotEmpty) pm.locality!.trim(),
        if ((pm.administrativeArea ?? '').trim().isNotEmpty)
          pm.administrativeArea!.trim(),
        if ((pm.postalCode ?? '').trim().isNotEmpty) pm.postalCode!.trim(),
      ];
      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }
}
