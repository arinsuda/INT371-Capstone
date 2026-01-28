class BookingCreateRequest {
  final int technicianId;
  final int technicianServiceId;
  final int addressId;
  final int timeSlotId;
  final String appointmentDate;
  final String? customerNote;
  final List<String> images;

  BookingCreateRequest({
    required this.technicianId,
    required this.technicianServiceId,
    required this.addressId,
    required this.timeSlotId,
    required this.appointmentDate,
    this.customerNote,
    this.images = const [],
  });
}

class BookingResponse {
  final bool success;
  final String message;
  final BookingData? data;

  BookingResponse({required this.success, required this.message, this.data});

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null ? BookingData.fromJson(json['data']) : null,
    );
  }
}

class BookingData {
  final int id;
  final String bookingNumber;
  final String status;
  final int technicianId;
  final DateTime appointmentDate;
  final double? finalPrice;
  final String? customerNote;
  final String recordedAddress;
  final String paymentMethod;
  final List<BookingImage> images;

  BookingData({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.technicianId,
    required this.appointmentDate,
    this.finalPrice,
    this.customerNote,
    required this.recordedAddress,
    required this.paymentMethod,
    required this.images,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['id'] ?? 0,
      bookingNumber: json['booking_number'] ?? "",
      status: json['status'] ?? "PENDING",
      technicianId: json['technician_id'] ?? 0,
      appointmentDate: json['appointment_date'] != null
          ? DateTime.parse(json['appointment_date'])
          : DateTime.now(),
      finalPrice: json['final_price'] != null
          ? double.tryParse(json['final_price'].toString())
          : null,
      customerNote: json['customer_note'],

      recordedAddress: json['recorded_address'] ?? "",
      paymentMethod: json['payment_method'] ?? "COD",

      images: json['images'] != null
          ? (json['images'] as List)
                .map((e) => BookingImage.fromJson(e))
                .toList()
          : [],
    );
  }
}

class BookingImage {
  final int id;
  final String imageUrl;

  BookingImage({required this.id, required this.imageUrl});

  factory BookingImage.fromJson(Map<String, dynamic> json) {
    return BookingImage(id: json['id'] ?? 0, imageUrl: json['image_url'] ?? "");
  }
}

class TimeSlotAvailability {
  final int id;
  final String label;
  final bool isAvailable;

  TimeSlotAvailability({
    required this.id,
    required this.label,
    required this.isAvailable,
  });

  factory TimeSlotAvailability.fromJson(Map<String, dynamic> json) {
    return TimeSlotAvailability(
      id: json['id'] ?? 0,
      label: json['label'] ?? "",
      isAvailable: json['is_available'] ?? false,
    );
  }
}

class CalendarResponse {
  final String month;
  final List<CalendarDay> days;

  CalendarResponse({required this.month, required this.days});

  factory CalendarResponse.fromJson(Map<String, dynamic> json) {
    return CalendarResponse(
      month: json['month'] ?? "",
      days: json['days'] != null
          ? (json['days'] as List).map((e) => CalendarDay.fromJson(e)).toList()
          : [],
    );
  }
}

class CalendarDay {
  final String date;
  final String status;
  final int availableSlots;
  final List<CalendarSlot> timeSlots;

  CalendarDay({
    required this.date,
    required this.status,
    required this.availableSlots,
    required this.timeSlots,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] ?? "",
      status: json['status'] ?? "CLOSED",
      availableSlots: json['available_slots'] ?? 0,
      timeSlots: json['time_slots'] != null
          ? (json['time_slots'] as List)
                .map((e) => CalendarSlot.fromJson(e))
                .toList()
          : [],
    );
  }
}

class CalendarSlot {
  final int id;
  final String timeRange;
  final bool isBooked;

  CalendarSlot({
    required this.id,
    required this.timeRange,
    required this.isBooked,
  });

  factory CalendarSlot.fromJson(Map<String, dynamic> json) {
    return CalendarSlot(
      id: json['id'] ?? 0,
      timeRange: json['time_range'] ?? "",
      isBooked: json['is_booked'] ?? false,
    );
  }
}
