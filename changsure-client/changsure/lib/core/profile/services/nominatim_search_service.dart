import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_result.dart';

class NominatimSearchService {
  // รับ Client เข้ามาแทนที่จะสร้างเอง
  const NominatimSearchService({required this.client});

  final http.Client client;

  Future<List<PlaceResult>> search(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=$limit&q=${Uri.encodeComponent(q)}',
    );

    try {
      final resp = await client.get(
        uri,
        headers: {
          'User-Agent': 'com.changsure.app (contact: support@changsure.app)',
        },
      );

      if (resp.statusCode != 200) return [];

      final data = jsonDecode(resp.body) as List<dynamic>;
      return data
          .map((e) {
            final m = e as Map<String, dynamic>;
            return PlaceResult(
              displayName: (m['display_name'] ?? '').toString(),
              lat: double.tryParse(m['lat'].toString()) ?? 0,
              lon: double.tryParse(m['lon'].toString()) ?? 0,
            );
          })
          .where((r) => r.lat != 0 && r.lon != 0)
          .toList();
    } catch (_) {
      return [];
    }
    // ไม่ต้อง close client ที่นี่ เพราะ Riverpod จะจัดการให้
  }
}
