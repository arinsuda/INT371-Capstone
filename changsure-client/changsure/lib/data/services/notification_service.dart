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
    final params = queryParameters?.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse(
      '${ApiConstants.baseUrl}$endpoint',
    ).replace(queryParameters: params);
  }

  Future<NotificationListResult> list({
    required String token,
    int? cursor,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final qp = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor > 0) qp['cursor'] = cursor;
    if (unreadOnly != null) qp['unread_only'] = unreadOnly;

    final url = _buildUri('/notifications', qp);
    final res = await http.get(url, headers: _headers(token));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return NotificationListResult.fromJson(body);
    }
    return NotificationListResult(items: [], hasMore: false);
  }

  Future<bool> markOneRead({
    required String token,
    required int id,
    bool isRead = true,
  }) async {
    final url = _buildUri('/notifications/$id');
    final res = await http.patch(
      url,
      headers: _headers(token),
      body: jsonEncode({'is_read': isRead}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> markRead({
    required String token,
    required List<int> ids,
    bool isRead = true,
  }) async {
    if (ids.isEmpty) return true;

    final url = _buildUri('/notifications');
    final res = await http.patch(
      url,
      headers: _headers(token),

      body: jsonEncode({'ids': ids, 'is_read': isRead}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> readAll({
    required String token,
    required List<int> unreadIds,
  }) async {
    if (unreadIds.isEmpty) return true;
    return markRead(token: token, ids: unreadIds);
  }
}
