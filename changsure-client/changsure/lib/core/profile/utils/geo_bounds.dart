import 'package:latlong2/latlong.dart';

class GeoBounds {
  static const double minLat = 5;
  static const double maxLat = 21;
  static const double minLng = 97;
  static const double maxLng = 106;

  static bool isInBounds(LatLng p) {
    return p.latitude >= minLat &&
        p.latitude <= maxLat &&
        p.longitude >= minLng &&
        p.longitude <= maxLng;
  }

  static LatLng clampOrDefault(
    LatLng p, {
    LatLng fallback = const LatLng(13.7649, 100.5383),
  }) {
    return isInBounds(p) ? p : fallback;
  }
}
