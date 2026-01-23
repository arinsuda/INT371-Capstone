import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  const LocationService();

  Future<LatLng> determinePosition({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'บริการระบุตำแหน่งถูกปิดอยู่ (Location Services disabled)',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง (Permission denied)');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่งถาวร (Permission denied forever)',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(timeout);

    return LatLng(position.latitude, position.longitude);
  }

  Future<LatLng?> currentPosition() async {
    try {
      return await determinePosition();
    } catch (_) {
      return null;
    }
  }
}
