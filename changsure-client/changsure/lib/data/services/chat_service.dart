import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat/chat_model.dart';

class ChatService {
  Future<List<ChatRoom>> getChatRooms(String token) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/chats/rooms");
    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json['data'] ?? [];
      return list.map((e) => ChatRoom.fromJson(e)).toList();
    });
  }

  Future<List<ChatMessage>> getChatHistory(String token, int bookingId) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/chats/rooms/$bookingId");
    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json is List ? json : (json['data'] ?? []);
      return list.map((e) => ChatMessage.fromJson(e)).toList();
    });
  }

  Future<void> markRoomAsRead(String token, int bookingId) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/chats/rooms/$bookingId/read",
    );

    final response = await http.post(uri, headers: _authHeader(token));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to mark as read: ${response.statusCode}');
    }
  }

  Future<ChatMessage> sendMessage(
    String token,
    SendMessageRequest req, {
    File? imageFile,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/chats/rooms/${req.bookingId}/messages",
    );

    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['booking_id'] = req.bookingId.toString();
    request.fields['type'] = req.type;
    request.fields['content'] = req.content;

    if (imageFile != null && req.type == 'IMAGE') {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response, (json) {
      return ChatMessage.fromJson(json['data'] ?? json);
    });
  }

  Map<String, String> _authHeader(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  T _handleResponse<T>(http.Response response, T Function(dynamic) onSuccess) {
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception("Server Error: ${response.statusCode}");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return onSuccess(json);
    }

    String msg = "Something went wrong";
    if (json is Map) {
      if (json['error'] is Map) {
        msg = json['error']['message'] ?? msg;
      } else if (json['message'] != null) {
        msg = json['message'];
      }
    }
    throw Exception(msg);
  }
}
