import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/booking/booking_model.dart';
import '../../core/constants/api_constants.dart';

class BookingService {
  Future<BookingResponse> createBooking(
    BookingCreateRequest req,
    String token,
  ) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/customers/me/bookings");
    final request = http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = "Bearer $token";

    request.fields.addAll({
      "technician_id": req.technicianId.toString(),
      "technician_service_id": req.technicianServiceId.toString(),
      "address_id": req.addressId.toString(),
      "time_slot_id": req.timeSlotId.toString(),
      "appointment_date": req.appointmentDate,
      "customer_note": req.customerNote ?? "",
    });

    if (req.images.isNotEmpty) {
      for (final path in req.images) {
        final file = File(path);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              "images",
              path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response, (json) => BookingResponse.fromJson(json));
  }

  Future<List<TimeSlotAvailability>> getAvailableTimeSlots({
    required String token,
    required int technicianId,
    required String date,
  }) async {
    final uri =
        Uri.parse(
          "${ApiConstants.baseUrl}/customers/me/bookings/availability",
        ).replace(
          queryParameters: {
            "technician_id": technicianId.toString(),
            "date": date,
          },
        );

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json['data'];
      return list.map((e) => TimeSlotAvailability.fromJson(e)).toList();
    });
  }

  Future<List<BookingData>> getMyBookings({
    required String token,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {"page": page.toString(), "limit": limit.toString()};
    if (status != null && status.isNotEmpty) {
      queryParams["status"] = status;
    }

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/customers/me/bookings",
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json['data']['items'];
      return list.map((e) => BookingData.fromJson(e)).toList();
    });
  }

  Future<BookingData> getCustomerBookingDetail({
    required String token,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/customers/me/bookings/$bookingId",
    );
    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      return BookingData.fromJson(json['data']);
    });
  }

  Future<BookingData> cancelBooking({
    required String token,
    required int bookingId,
    String reason = "",
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/customers/me/bookings/$bookingId/cancel",
    );

    final response = await http.patch(
      uri,
      headers: _authHeader(token),
      body: jsonEncode({"reason": reason}),
    );

    return _handleResponse(response, (json) {
      return BookingData.fromJson(json['data']);
    });
  }

  Future<BookingData> getTechnicianBookingDetail({
    required String token,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/me/bookings/$bookingId",
    );
    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      return BookingData.fromJson(json['data']);
    });
  }

  Future<CalendarResponse> getTechnicianCalendar({
    required String token,
    required int technicianId,
    required String month,
  }) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/technicians/calendar")
        .replace(
          queryParameters: {
            "technician_id": technicianId.toString(),
            "month": month,
          },
        );

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) => CalendarResponse.fromJson(json));
  }

  Map<String, String> _authHeader(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

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
}
