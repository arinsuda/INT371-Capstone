class BookingSnapshot {
  final int id;
  final String bookingNumber;
  final String status;
  final double? finalPrice;
  final String appointmentDate;
  final String technicianName;
  final String serviceName;

  const BookingSnapshot({
    required this.id,
    required this.bookingNumber,
    required this.status,
    this.finalPrice,
    required this.appointmentDate,
    required this.technicianName,
    required this.serviceName,
  });

  factory BookingSnapshot.fromJson(Map<String, dynamic> json) {
    return BookingSnapshot(
      id: json['id'] as int,
      bookingNumber: json['booking_number'] as String,
      status: json['status'] as String,
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      appointmentDate: json['appointment_date'] as String,
      technicianName: json['technician_name'] as String,
      serviceName: json['service_name'] as String,
    );
  }
}

class CreateQRResponse {
  final String sourceId;
  final String? qrCodeUri;
  final double amount;
  final String currency;
  final DateTime expiresAt;
  final String status;
  final int bookingId;
  final BookingSnapshot booking;
  final String? description;
  final bool qrCodeReady;

  const CreateQRResponse({
    required this.sourceId,
    this.qrCodeUri,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    required this.status,
    required this.bookingId,
    required this.booking,
    this.description,
    required this.qrCodeReady,
  });

  factory CreateQRResponse.fromJson(Map<String, dynamic> json) {
    return CreateQRResponse(
      sourceId: json['source_id'] as String,
      qrCodeUri: json['qr_code_uri'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: json['status'] as String,
      bookingId: json['booking_id'] as int,
      booking: BookingSnapshot.fromJson(
        json['booking'] as Map<String, dynamic>,
      ),
      description: json['description'] as String?,
      qrCodeReady: json['qr_code_ready'] as bool,
    );
  }
}

class PaymentStatusResponse {
  final bool hasPaid;
  final String status;

  const PaymentStatusResponse({required this.hasPaid, required this.status});

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      hasPaid: json['has_paid'] as bool,
      status: json['data']['status'] as String,
    );
  }
}
