import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat/chat_model.dart';

// ============================================================================
// EXCEPTIONS
// ============================================================================

/// Base exception for chat service errors
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

/// Network-related errors
class NetworkException extends ChatServiceException {
  NetworkException(String message, {dynamic originalError})
    : super(message, originalError: originalError);
}

/// Authentication errors
class AuthenticationException extends ChatServiceException {
  AuthenticationException(String message) : super(message, statusCode: 401);
}

/// Validation errors
class ValidationException extends ChatServiceException {
  ValidationException(String message) : super(message, statusCode: 400);
}

/// Not found errors
class NotFoundException extends ChatServiceException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

// ============================================================================
// CHAT SERVICE
// ============================================================================

/// Service for handling chat-related API calls
/// Includes error handling, retry logic, and request validation
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

  // ========== PUBLIC METHODS ==========

  /// Get all chat rooms for the current user
  ///
  /// Throws [ChatServiceException] if the request fails
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

  /// Get chat history for a specific booking
  ///
  /// Throws [ChatServiceException] if the request fails
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

  /// Mark a chat room as read
  ///
  /// Throws [ChatServiceException] if the request fails
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

  /// Send a message (text or image)
  ///
  /// Throws [ChatServiceException] if the request fails
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

  // ========== PRIVATE HELPER METHODS ==========

  /// Execute a request with retry logic for transient failures
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

        // Exponential backoff
        final delay = Duration(milliseconds: 100 * (1 << (attempts - 1)));
        await Future.delayed(delay);
      }
    }
  }

  /// Determine if a request should be retried based on the error and attempt count
  bool _shouldRetry(dynamic error, int attempts) {
    if (attempts >= _maxRetries) return false;

    // Retry on network errors
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;

    // Retry on specific HTTP status codes
    if (error is http.Response) {
      final status = error.statusCode;
      return status == 429 || // Too Many Requests
          status == 502 || // Bad Gateway
          status == 503 || // Service Unavailable
          status == 504; // Gateway Timeout
    }

    return false;
  }

  /// Add image file to multipart request
  Future<void> _addImageToRequest(
    http.MultipartRequest request,
    File imageFile,
  ) async {
    // Validate file exists
    if (!await imageFile.exists()) {
      throw ValidationException('Image file does not exist');
    }

    // Validate file size (10MB max)
    final fileSize = await imageFile.length();
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      throw ValidationException('Image file too large (max 10MB)');
    }

    // Determine MIME type
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');

    // Validate MIME type
    if (mimeSplit[0] != 'image') {
      throw ValidationException('File must be an image');
    }

    // Add file to request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );
  }

  /// Handle HTTP response and parse JSON
  T _handleResponse<T>(http.Response response, T Function(dynamic) onSuccess) {
    // Parse JSON response
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

    // Handle successful response
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

    // Extract error message
    String message = 'Something went wrong';
    if (json is Map) {
      if (json['error'] is Map) {
        message = json['error']['message'] ?? message;
      } else if (json['message'] != null) {
        message = json['message'];
      }
    }

    // Throw appropriate exception based on status code
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

  /// Create authorization header
  Map<String, String> _authHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // ========== VALIDATION METHODS ==========

  /// Validate authentication token
  void _validateToken(String token) {
    if (token.isEmpty) {
      throw AuthenticationException('Authentication token is required');
    }
  }

  /// Validate booking ID
  void _validateBookingId(int bookingId) {
    if (bookingId <= 0) {
      throw ValidationException('Invalid booking ID');
    }
  }

  /// Validate send message request
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

  // ========== CLEANUP ==========

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}
