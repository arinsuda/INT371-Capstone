import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment/payment_model.dart';
import '../../core/constants/api_constants.dart';

class PaymentService {
  Map<String, String> _authHeader(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) onSuccess,
  ) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception("Server Error: ${response.statusCode}");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return onSuccess(json);
    }

    String errorMessage = "Something went wrong";
    if (json.containsKey('error')) {
      if (json['error'] is Map) {
        errorMessage = json['error']['message'] ?? errorMessage;
      } else if (json['error'] is String) {
        errorMessage = json['error'];
      }
    } else if (json.containsKey('message')) {
      errorMessage = json['message'];
    }

    throw Exception(errorMessage);
  }

  Future<CreateQRResponse> createQR({
    required String token,
    required int bookingId,
    required double amount,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/payments/qr');
    final response = await http.post(
      uri,
      headers: _authHeader(token),
      body: jsonEncode({'booking_id': bookingId, 'amount': amount}),
    );
    return _handleResponse(response, (json) => CreateQRResponse.fromJson(json));
  }

  Future<PaymentStatusResponse> checkPaymentStatus({
    required String token,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/payments/bookings/$bookingId/status',
    );
    final response = await http.get(uri, headers: _authHeader(token));
    return _handleResponse(
      response,
      (json) => PaymentStatusResponse.fromJson(json),
    );
  }

  Future<void> cancelQR({required String token, required int bookingId}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/payments/bookings/$bookingId/qr',
    );
    final response = await http.delete(uri, headers: _authHeader(token));
    _handleResponse(response, (_) => null);
  }
}
