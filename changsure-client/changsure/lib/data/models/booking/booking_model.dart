class BookingCreateRequest {
  final int technicianId;
  final int technicianServiceId;
  final int addressId;
  final int timeSlotId;
  final String appointmentDate;
  final String? customerNote;
  final List<String> images; // path file

  BookingCreateRequest({
    required this.technicianId,
    required this.technicianServiceId,
    required this.addressId,
    required this.timeSlotId,
    required this.appointmentDate,
    this.customerNote,
    required this.images,
  });

  /// ❗ ใช้เฉพาะ fields ธรรมดา (ไม่รวม images)
  Map<String, String> toFields() {
    final map = <String, String>{
      "technician_id": technicianId.toString(),
      "technician_service_id": technicianServiceId.toString(),
      "address_id": addressId.toString(),
      "time_slot_id": timeSlotId.toString(),
      "appointment_date": appointmentDate,
    };

    if (customerNote != null && customerNote!.trim().isNotEmpty) {
      map["customer_note"] = customerNote!;
    }

    return map;
  }
}

class BookingResponse {
  final BookingData data;
  final String message;
  final bool success;

  BookingResponse({
    required this.data,
    required this.message,
    required this.success,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      data: BookingData.fromJson(json['data']),
      message: json['message'],
      success: json['success'],
    );
  }
}
class BookingData {
  final int id;
  final int technicianId;
  final int technicianServiceId;
  final int addressId;
  final int timeSlotId;
  final DateTime appointmentDate;
  final String recordedAddress;
  final int? priceAmount;
  final String? paymentMethod;
  final String? customerNote;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BookingImage> images;

  BookingData({
    required this.id,
    required this.technicianId,
    required this.technicianServiceId,
    required this.addressId,
    required this.timeSlotId,
    required this.appointmentDate,
    required this.recordedAddress,
    required this.priceAmount,
    required this.paymentMethod,
    required this.customerNote,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['id'],
      technicianId: json['technician_id'],
      technicianServiceId: json['technician_service_id'],
      addressId: json['address_id'],
      timeSlotId: json['time_slot_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      recordedAddress: json['recorded_address'] ?? '',
      priceAmount: json['price_amount'] as int?,
      paymentMethod: json['payment_method']?.toString(),
      customerNote: json['customer_note'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      images: json['images'] == null
          ? <BookingImage>[]
          : (json['images'] as List)
          .map((e) => BookingImage.fromJson(e))
          .toList(),
    );
  }
}

class BookingImage {
  final int id;
  final String imageUrl;

  BookingImage({
    required this.id,
    required this.imageUrl,
  });

  factory BookingImage.fromJson(Map<String, dynamic> json) {
    return BookingImage(
      id: json['id'],
      imageUrl: json['image_url'],
    );
  }
}


class TimeSlot {
  final int id;
  final String startTime;
  final String endTime;
  final String displayText;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.displayText,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      displayText: json['display_text'],
    );
  }
}
