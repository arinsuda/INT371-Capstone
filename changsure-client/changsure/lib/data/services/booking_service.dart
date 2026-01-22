import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking/booking_model.dart';
import '../../core/constants/api_constants.dart';

class BookingService {
  Future<BookingResponse> createBooking(
      BookingCreateRequest req,
      String token,
      ) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}/bookings");

    final request = http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = "Bearer $token";
    // ❗ ห้าม set Content-Type เอง

    // fields (ข้อความ)
    request.fields.addAll({
      "technician_id": req.technicianId.toString(),
      "technician_service_id": req.technicianServiceId.toString(),
      "address_id": req.addressId.toString(),
      "time_slot_id": req.timeSlotId.toString(),
      "appointment_date": req.appointmentDate, // yyyy-mm-dd
      "customer_note": req.customerNote ?? "",
    });

    // files
    for (final path in req.images) {
      request.files.add(
        await http.MultipartFile.fromPath("images", path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BookingResponse.fromJson(json);
    } else {
      print("BOOKING ERROR => ${response.body}");
      throw Exception(json["message"] ?? "Create booking failed");
    }
  }




  Future<List<TimeSlot>> getTimeSlots(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/time-slots"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final List list = json['data'];

      return list.map((e) => TimeSlot.fromJson(e)).toList();
    } else {
      print("❌ TIME SLOT ERROR: ${response.body}");
      throw Exception("Failed to load time slots");
    }
  }
}
