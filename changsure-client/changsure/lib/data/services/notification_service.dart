import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:changsure/core/constants/api_constants.dart';
import 'package:changsure/data/models/notification_model.dart';

class NotificationService {
  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse(
      '${ApiConstants.baseUrl}$endpoint',
    ).replace(queryParameters: queryParameters);
  }

  Future<int> getUnreadCount(String token) async {
    final url = _buildUri('/notifications/unread-count');
    final res = await http.get(url, headers: _headers(token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      return (body['unread_count'] ?? 0) as int;
    }
    return 0;
  }

  Future<List<NotificationModel>> list({
    required String token,
    int? cursor,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final qp = <String, String>{'limit': '$limit'};

    if (cursor != null && cursor > 0) {
      qp['cursor'] = '$cursor';
    }

    if (unreadOnly != null) {
      qp['unread_only'] = unreadOnly ? 'true' : 'false';
    }

    final url = _buildUri('/notifications', qp);

    final res = await http.get(url, headers: _headers(token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);

      final items = body['items'];

      if (items is List) {
        return items.map((e) => NotificationModel.fromJson(e)).toList();
      }
    }
    return [];
  }

  Future<bool> markRead({required String token, required List<int> ids}) async {
    final url = _buildUri('/notifications/read');
    final res = await http.patch(
      url,
      headers: _headers(token),
      body: jsonEncode({'ids': ids}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> readAll(String token) async {
    final url = _buildUri('/notifications/read-all');
    final res = await http.patch(url, headers: _headers(token));
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
