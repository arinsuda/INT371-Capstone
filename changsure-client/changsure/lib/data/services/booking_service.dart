import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/booking/booking_model.dart';
import '../../core/constants/api_constants.dart';

enum BookingAction { accept, reject, start, complete }

extension BookingActionExtension on BookingAction {
  String get value {
    switch (this) {
      case BookingAction.accept:
        return "ACCEPT";
      case BookingAction.reject:
        return "REJECT";
      case BookingAction.start:
        return "START";
      case BookingAction.complete:
        return "COMPLETE";
    }
  }
}

class BookingService {
  // ─────────────────────────────────────────────
  // CUSTOMER ENDPOINTS
  // ─────────────────────────────────────────────

  /// POST /customers/:customerId/bookings
  Future<BookingResponse> createBooking(
    BookingCreateRequest req,
    String token,
    int customerId,
  ) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/customers/$customerId/bookings',
    );
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

  /// GET /customers/:customerId/bookings
  Future<List<Booking>> getMyBookings({
    required String token,
    required int customerId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {"page": page.toString(), "limit": limit.toString()};
    if (status != null && status.isNotEmpty) {
      queryParams["status"] = status;
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/customers/$customerId/bookings',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json['data']['items'];
      return list.map((e) => Booking.fromJson(e)).toList();
    });
  }

  /// GET /customers/:customerId/bookings/:bookingId
  Future<Booking> getCustomerBookingDetail({
    required String token,
    required int customerId,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/customers/$customerId/bookings/$bookingId",
    );
    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) => Booking.fromJson(json['data']));
  }

  /// PATCH /customers/:customerId/bookings/:bookingId
  /// body: { "status": "cancelled", "reason": "..." }
  Future<Booking> cancelBooking({
    required String token,
    required int customerId,
    required int bookingId,
    String reason = "",
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/customers/$customerId/bookings/$bookingId",
    );

    final response = await http.patch(
      uri,
      headers: _authHeader(token),
      body: jsonEncode({"status": "cancelled", "reason": reason}),
    );

    return _handleResponse(response, (json) => Booking.fromJson(json['data']));
  }

  /// GET /customers/:customerId/bookings/availability?technician_id=&date=
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String token,
    required int customerId,
    required int technicianId,
    required String date,
  }) async {
    final uri =
        Uri.parse(
          "${ApiConstants.baseUrl}/customers/$customerId/bookings/availability",
        ).replace(
          queryParameters: {
            "technician_id": technicianId.toString(),
            "date": date,
          },
        );

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json['data'];
      return list.map((e) => TimeSlot.fromJson(e)).toList();
    });
  }

  // ─────────────────────────────────────────────
  // TECHNICIAN BOOKING ENDPOINTS
  // ─────────────────────────────────────────────

  /// GET /technicians/:technicianId/bookings
  Future<List<Booking>> getTechnicianBookings({
    required String token,
    required int technicianId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {"page": page.toString(), "limit": limit.toString()};
    if (status != null && status.isNotEmpty) {
      queryParams["status"] = status;
    }

    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/bookings",
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final List list = json['data']['items'];
      return list.map((e) => Booking.fromJson(e)).toList();
    });
  }

  /// GET /technicians/:technicianId/bookings/:bookingId
  Future<Booking> getTechnicianBookingDetail({
    required String token,
    required int technicianId,
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/bookings/$bookingId",
    );
    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) => Booking.fromJson(json['data']));
  }

  /// PATCH /technicians/:technicianId/bookings/:bookingId
  /// body: { "action": "ACCEPT|REJECT|START|COMPLETE", "reason"?: "..." }
  Future<Booking> updateBookingStatus({
    required String token,
    required int technicianId,
    required int bookingId,
    required BookingAction action,
    String? reason,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/bookings/$bookingId",
    );

    final body = {
      "status": action.value,
      if (reason != null && reason.isNotEmpty) "reason": reason,
    };

    final response = await http.patch(
      uri,
      headers: _authHeader(token),
      body: jsonEncode(body),
    );

    return _handleResponse(response, (json) => Booking.fromJson(json['data']));
  }

  // ─────────────────────────────────────────────
  // TECHNICIAN CALENDAR ENDPOINTS
  // route group: /technicians/:technicianId/calendar
  // ─────────────────────────────────────────────

  /// GET /technicians/:technicianId/calendar/:month  (month = "yyyy-MM")
  /// ดูปฏิทินรายเดือน — ใช้ได้ทั้ง Customer และ Technician
  Future<PublicCalendarResponse> getPublicCalendar({
    required String token,
    required int technicianId,
    required String month,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/calendar/$month",
    );

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return PublicCalendarResponse.fromJson(data);
    });
  }

  /// GET /technicians/:technicianId/calendar/:month  (month = "yyyy-MM")
  /// ช่างดูปฏิทินของตัวเอง — ชี้ไป endpoint เดียวกับ getPublicCalendar
  Future<PublicCalendarResponse> getTechnicianCalendar({
    required String token,
    required int technicianId,
    required String month,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/calendar/$month",
    );

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(response, (json) {
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return PublicCalendarResponse.fromJson(data);
    });
  }

  /// GET /technicians/:technicianId/calendar/:date  (date = "yyyy-MM-dd")
  /// ดูรายการจองรายวัน พร้อม optional ?timeslot=<id>
  Future<List<TechnicianBooking>> getTechnicianCalendarByDate({
    required String token,
    required int technicianId,
    required String date,
    int? timeSlotId,
  }) async {
    final uri =
        Uri.parse(
          "${ApiConstants.baseUrl}/technicians/$technicianId/calendar/$date",
        ).replace(
          queryParameters: timeSlotId != null
              ? {"timeslot": timeSlotId.toString()}
              : null,
        );

    final response = await http.get(uri, headers: _authHeader(token));

    return _handleResponse(
      response,
      (json) => (json['data'] as List)
          .map((e) => TechnicianBooking.fromJson(e))
          .toList(),
    );
  }

  /// PATCH /technicians/:technicianId/calendar
  /// body: { "date": "yyyy-MM-dd", "is_open": bool }
  Future<UpdateTechnicianCalendarResponse> updateTechnicianCalendarByDate({
    required String token,
    required int technicianId,
    required String date,
    required bool isOpen,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/calendar",
    );

    final response = await http.patch(
      uri,
      headers: _authHeader(token),
      body: jsonEncode({"date": date, "is_open": isOpen}),
    );

    return _handleResponse(
      response,
      (json) => UpdateTechnicianCalendarResponse.fromJson(json['data']),
    );
  }

  /// PUT /technicians/:technicianId/calendar/:date/time-slot
  /// body: { "time_slot_ids": [...], "is_default": bool }
  Future<UpdateTimeSlotsResponse> updateTechnicianCalendarByTimeslot({
    required String token,
    required int technicianId,
    required String date,
    required bool isDefault,
    required List<int> timeSlotIds,
  }) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}/technicians/$technicianId/calendar/$date/time-slot",
    );

    final response = await http.put(
      uri,
      headers: _authHeader(token),
      body: jsonEncode({"time_slot_ids": timeSlotIds, "is_default": isDefault}),
    );

    return _handleResponse(
      response,
      (json) => UpdateTimeSlotsResponse.fromJson(json['data']),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

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
