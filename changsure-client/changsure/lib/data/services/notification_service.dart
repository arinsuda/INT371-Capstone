import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:changsure/core/constants/api_constants.dart';

class NotificationService {
  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<int> getUnreadCount(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count');
    final res = await http.get(url, headers: _headers(token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);

      final data = body['data'] ?? body;
      return (data['unread_count'] ?? 0) as int;
    }
    return 0;
  }

  Future<List<dynamic>> list({
    required String token,
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final qp = <String, String>{'page': '$page', 'limit': '$limit'};
    if (unreadOnly != null) qp['unread_only'] = unreadOnly ? 'true' : 'false';

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/notifications',
    ).replace(queryParameters: qp);

    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      final data = body['data'] ?? body;

      if (data is List) return data;
      if (data is Map && data['items'] is List) return data['items'];
      return const [];
    }
    return const [];
  }

  Future<bool> markRead({required String token, required List<int> ids}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/notifications/read');
    final res = await http.patch(
      url,
      headers: _headers(token),
      body: jsonEncode({'ids': ids}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> readAll(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/notifications/read-all');
    final res = await http.patch(url, headers: _headers(token));
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
