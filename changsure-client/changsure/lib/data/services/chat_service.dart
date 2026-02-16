import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat/chat_model.dart';

class ChatServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ChatServiceException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('ChatServiceException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    return buffer.toString();
  }
}

class NetworkException extends ChatServiceException {
  NetworkException(String message, {dynamic originalError})
    : super(message, originalError: originalError);
}

class AuthenticationException extends ChatServiceException {
  AuthenticationException(String message) : super(message, statusCode: 401);
}

class ValidationException extends ChatServiceException {
  ValidationException(String message) : super(message, statusCode: 400);
}

class NotFoundException extends ChatServiceException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class ChatService {
  final http.Client _client;
  final Duration _timeout;
  final int _maxRetries;

  ChatService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) : _client = client ?? http.Client(),
       _timeout = timeout,
       _maxRetries = maxRetries;

  Future<List<ChatRoom>> getChatRooms(String token) async {
    _validateToken(token);

    final uri = Uri.parse('${ApiConstants.baseUrl}/chats/rooms');

    try {
      final response = await _executeWithRetry(
        () => _client.get(uri, headers: _authHeader(token)).timeout(_timeout),
      );

      return _handleResponse(response, (json) {
        final List list = json['data'] ?? [];
        return list
            .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Request timed out', originalError: e);
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException('Failed to get chat rooms', originalError: e);
    }
  }

  Future<List<ChatMessage>> getChatHistory(
    String token,
    int bookingId, {
    int limit = 50,
    int offset = 0,
  }) async {
    _validateToken(token);
    _validateBookingId(bookingId);

    final uri = Uri.parse('${ApiConstants.baseUrl}/chats/rooms/$bookingId')
        .replace(
          queryParameters: {
            'limit': limit.toString(),
            'offset': offset.toString(),
          },
        );

    try {
      final response = await _executeWithRetry(
        () => _client.get(uri, headers: _authHeader(token)).timeout(_timeout),
      );

      return _handleResponse(response, (json) {
        final List list = json is List ? json : (json['data'] ?? []);
        return list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Request timed out', originalError: e);
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        'Failed to get chat history',
        originalError: e,
      );
    }
  }

  Future<void> markRoomAsRead(String token, int bookingId) async {
    _validateToken(token);
    _validateBookingId(bookingId);

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/chats/rooms/$bookingId/read',
    );

    try {
      final response = await _executeWithRetry(
        () => _client.post(uri, headers: _authHeader(token)).timeout(_timeout),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatServiceException(
          'Failed to mark room as read',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Request timed out', originalError: e);
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        'Failed to mark room as read',
        originalError: e,
      );
    }
  }

  Future<ChatMessage> sendMessage(
    String token,
    SendMessageRequest req, {
    File? imageFile,
  }) async {
    _validateToken(token);
    _validateSendMessageRequest(req, imageFile);

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/chats/rooms/${req.bookingId}/messages',
    );

    try {
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['booking_id'] = req.bookingId.toString();
      request.fields['type'] = req.type.value;
      request.fields['content'] = req.content;

      if (imageFile != null && req.type == MessageType.image) {
        await _addImageToRequest(request, imageFile);
      }

      final streamedResponse = await _executeWithRetry(
        () => request.send().timeout(_timeout),
      );

      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, (json) {
        final messageData = json['data'] ?? json;
        return ChatMessage.fromJson(messageData as Map<String, dynamic>);
      });
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Request timed out', originalError: e);
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException('Failed to send message', originalError: e);
    }
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() request) async {
    int attempts = 0;

    while (true) {
      try {
        attempts++;
        return await request();
      } catch (e) {
        final shouldRetry = _shouldRetry(e, attempts);

        if (!shouldRetry) {
          rethrow;
        }

        final delay = Duration(milliseconds: 100 * (1 << (attempts - 1)));
        await Future.delayed(delay);
      }
    }
  }

  bool _shouldRetry(dynamic error, int attempts) {
    if (attempts >= _maxRetries) return false;

    if (error is SocketException) return true;
    if (error is TimeoutException) return true;

    if (error is http.Response) {
      final status = error.statusCode;
      return status == 429 || status == 502 || status == 503 || status == 504;
    }

    return false;
  }

  Future<void> markMessagesAsRead(
    String token,
    int bookingId,
    List<int> messageIds,
  ) async {
    _validateToken(token);
    _validateBookingId(bookingId);

    if (messageIds.isEmpty) {
      throw ValidationException('Message IDs cannot be empty');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/chats/rooms/$bookingId/messages/read',
    );

    try {
      final response = await _executeWithRetry(
        () => _client
            .post(
              uri,
              headers: _authHeader(token),
              body: jsonEncode({'message_ids': messageIds}),
            )
            .timeout(_timeout),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatServiceException(
          'Failed to mark messages as read',
          statusCode: response.statusCode,
        );
      }

      print('✅ Marked ${messageIds.length} messages as read');
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Request timed out', originalError: e);
    } catch (e) {
      if (e is ChatServiceException) rethrow;
      throw ChatServiceException(
        'Failed to mark messages as read',
        originalError: e,
      );
    }
  }

  Future<void> _addImageToRequest(
    http.MultipartRequest request,
    File imageFile,
  ) async {
    if (!await imageFile.exists()) {
      throw ValidationException('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    const maxSize = 10 * 1024 * 1024;
    if (fileSize > maxSize) {
      throw ValidationException('Image file too large (max 10MB)');
    }

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');

    if (mimeSplit[0] != 'image') {
      throw ValidationException('File must be an image');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );
  }

  T _handleResponse<T>(http.Response response, T Function(dynamic) onSuccess) {
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw ChatServiceException(
        'Invalid JSON response from server',
        statusCode: response.statusCode,
        originalError: e,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return onSuccess(json);
      } catch (e) {
        throw ChatServiceException(
          'Failed to parse response data',
          statusCode: response.statusCode,
          originalError: e,
        );
      }
    }

    String message = 'Something went wrong';
    if (json is Map) {
      if (json['error'] is Map) {
        message = json['error']['message'] ?? message;
      } else if (json['message'] != null) {
        message = json['message'];
      }
    }

    switch (response.statusCode) {
      case 401:
        throw AuthenticationException(message);
      case 404:
        throw NotFoundException(message);
      case 400:
      case 422:
        throw ValidationException(message);
      default:
        throw ChatServiceException(message, statusCode: response.statusCode);
    }
  }

  Map<String, String> _authHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  void _validateToken(String token) {
    if (token.isEmpty) {
      throw AuthenticationException('Authentication token is required');
    }
  }

  void _validateBookingId(int bookingId) {
    if (bookingId <= 0) {
      throw ValidationException('Invalid booking ID');
    }
  }

  void _validateSendMessageRequest(SendMessageRequest req, File? imageFile) {
    if (!req.validate()) {
      throw ValidationException('Invalid message request');
    }

    if (req.type == MessageType.image && imageFile == null) {
      throw ValidationException('Image file is required for IMAGE messages');
    }

    if (req.type == MessageType.text && req.content.trim().isEmpty) {
      throw ValidationException('Content is required for TEXT messages');
    }
  }

  void dispose() {
    _client.close();
  }

  Future<List<ChatMessage>> getChatMessages(
      String token,
      int roomId,
      ) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/chats/rooms/$roomId'),
      headers: {
        'Content-Type': 'application/json',
        ..._authHeader(token), // ✅ ใช้ spread operator
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];

      return data.map((e) => ChatMessage.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load chat messages');
    }
  }

}
