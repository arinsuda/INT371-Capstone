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
    if (json.containsKey('message')) {
      errorMessage = json['message'];
    } else if (json.containsKey('code')) {
      errorMessage = json['code'];
    }

    throw Exception(errorMessage);
  }

  Future<CreatePaymentResponse> createPayment({
    required String token,
    required int bookingId,
    required double amount,
    String method = 'promptpay',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/payments');
    final response = await http.post(
      uri,
      headers: _authHeader(token),
      body: jsonEncode({
        'booking_id': bookingId,
        'amount': amount,
        'method': method,
      }),
    );
    return _handleResponse(
      response,
      (json) => CreatePaymentResponse.fromJson(json['data']),
    );
  }

  Future<PaymentStatusResponse> checkPaymentStatus({
    required String token,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/bookings/$bookingId/payments/status',
    );
    final response = await http.get(uri, headers: _authHeader(token));
    return _handleResponse(
      response,
      (json) => PaymentStatusResponse.fromJson(json),
    );
  }

  Future<void> cancelPendingPayment({
    required String token,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/bookings/$bookingId/payments/pending',
    );
    final response = await http.delete(uri, headers: _authHeader(token));
    if (response.statusCode != 204) {
      _handleResponse(response, (_) => null);
    }
  }
}
