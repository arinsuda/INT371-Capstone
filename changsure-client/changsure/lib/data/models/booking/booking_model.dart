// ==========================================
// 1. Core Booking Models
// ==========================================

import 'package:changsure/core/profile/utils/time_parser.dart';

class Booking {
  final int id;
  final String bookingNumber;
  final int customerId;
  final int technicianId;
  final int technicianServiceId;
  final int addressId;
  final int timeSlotId;
  final DateTime appointmentDate;
  final String recordedAddress;
  final String pricingType;
  final double? quotedPriceFixed;
  final double? quotedPriceMin;
  final double? quotedPriceMax;
  final String paymentMethod;
  final String customerNote;
  final double? finalPrice;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TimeSlotForBooking? timeSlot;
  final Customer? customer;
  final Technician? technician;
  final TechnicianService? technicianService;
  final List<BookingImage>? images;

  Booking({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    required this.technicianId,
    required this.technicianServiceId,
    required this.addressId,
    required this.timeSlotId,
    required this.appointmentDate,
    required this.recordedAddress,
    required this.pricingType,
    this.quotedPriceFixed,
    this.quotedPriceMin,
    this.quotedPriceMax,
    required this.paymentMethod,
    required this.customerNote,
    this.finalPrice,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.timeSlot,
    this.customer,
    this.technician,
    this.technicianService,
    this.images,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      bookingNumber: json['booking_number'] ?? '',
      customerId: json['customer_id'] ?? 0,
      technicianId: json['technician_id'] ?? 0,
      technicianServiceId: json['technician_service_id'] ?? 0,
      addressId: json['address_id'] ?? 0,
      timeSlotId: json['time_slot_id'] ?? 0,
      appointmentDate: TimeParser.parse(json['appointment_date']),
      recordedAddress: json['recorded_address'] ?? '',
      pricingType: json['pricing_type'] ?? '',
      quotedPriceFixed: json['quoted_price_fixed']?.toDouble(),
      quotedPriceMin: json['quoted_price_min']?.toDouble(),
      quotedPriceMax: json['quoted_price_max']?.toDouble(),
      paymentMethod: json['payment_method'] ?? 'COD',
      customerNote: json['customer_note'] ?? '',
      finalPrice: json['final_price'] != null
          ? double.tryParse(json['final_price'].toString())
          : null,
      status: json['status'] ?? '',
      createdAt: TimeParser.parseNullable(json['created_at']),
      updatedAt: TimeParser.parseNullable(json['updated_at']),
      timeSlot: json['time_slot'] != null
          ? TimeSlotForBooking.fromJson(json['time_slot'])
          : null,
      technician: json['technician'] != null
          ? Technician.fromJson(json['technician'])
          : null,
      technicianService: json['technician_service'] != null
          ? TechnicianService.fromJson(json['technician_service'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
                .map((img) => BookingImage.fromJson(img))
                .toList()
          : null,
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_number': bookingNumber,
      'customer_id': customerId,
      'technician_id': technicianId,
      'technician_service_id': technicianServiceId,
      'address_id': addressId,
      'time_slot_id': timeSlotId,
      'appointment_date': appointmentDate.toIso8601String(),
      'recorded_address': recordedAddress,
      'pricing_type': pricingType,
      'quoted_price_fixed': quotedPriceFixed,
      'quoted_price_min': quotedPriceMin,
      'quoted_price_max': quotedPriceMax,
      'payment_method': paymentMethod,
      'customer_note': customerNote,
      'final_price': finalPrice,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String getStatusText() {
    switch (status) {
      case 'PENDING':
        return 'รอช่างรับงาน';
      case 'ACCEPTED':
        return 'ช่างรับงานแล้ว';
      case 'IN_PROGRESS':
        return 'กำลังดำเนินการ';
      case 'WAITING_PAYMENT':
        return 'รอชำระเงิน';
      case 'COMPLETED':
        return 'เสร็จสิ้น';
      case 'CANCELLED':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  int getStatusStep() {
    switch (status) {
      case 'PENDING':
        return 1;
      case 'ACCEPTED':
        return 2;
      case 'IN_PROGRESS':
        return 3;
      case 'WAITING_PAYMENT':
      case 'COMPLETED':
        return 4;
      default:
        return 0;
    }
  }

  String getPriceDisplay() {
    if (pricingType == 'FIXED' && quotedPriceFixed != null) {
      return '฿${quotedPriceFixed!.toStringAsFixed(0)}';
    } else if (pricingType == 'RANGE') {
      return '฿${quotedPriceMin?.toStringAsFixed(0) ?? '0'} - ฿${quotedPriceMax?.toStringAsFixed(0) ?? '0'}';
    }
    return '฿0';
  }
}

class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? phoneNumber;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.phoneNumber,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
    );
  }

  String getFullName() => '$firstName $lastName';
}

class BookingImage {
  final int id;
  final int? bookingId;
  final String imageUrl;
  final DateTime? createdAt;

  BookingImage({
    required this.id,
    this.bookingId,
    required this.imageUrl,
    this.createdAt,
  });

  factory BookingImage.fromJson(Map<String, dynamic> json) {
    return BookingImage(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'],
      imageUrl: json['image_url'] ?? '',
      createdAt: TimeParser.parseNullable(json['created_at']),
    );
  }
}

// ==========================================
// 2. Supporting Models (Technician, Service, Slot)
// ==========================================
class TimeSlotForBooking {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;

  TimeSlotForBooking({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory TimeSlotForBooking.fromJson(Map<String, dynamic> json) {
    return TimeSlotForBooking(
      id: json['id'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  String getTimeRange() => '$startTime - $endTime';
}

class Technician {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? phoneNumber;

  Technician({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.phoneNumber,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? 0,
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
    );
  }

  String getFullName() => '$firstName $lastName';
}

class TechnicianService {
  final int id;
  final String pricingType;
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;
  final Service? service;

  TechnicianService({
    required this.id,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
    this.service,
  });

  factory TechnicianService.fromJson(Map<String, dynamic> json) {
    return TechnicianService(
      id: json['id'] ?? 0,
      pricingType: json['pricing_type'] ?? '',
      priceFixed: json['price_fixed']?.toDouble(),
      priceMin: json['price_min']?.toDouble(),
      priceMax: json['price_max']?.toDouble(),
      service: json['service'] != null
          ? Service.fromJson(json['service'])
          : null,
    );
  }
}

class Service {
  final int id;
  final String serName;
  final String? description;
  final List<String>? imageUrls;

  Service({
    required this.id,
    required this.serName,
    this.description,
    this.imageUrls,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      serName: json['ser_name'] ?? '',
      description: json['description'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
    );
  }

  String getFirstImage() =>
      (imageUrls != null && imageUrls!.isNotEmpty) ? imageUrls!.first : '';
}

// ==========================================
// 3. Request & Response Wrappers
// ==========================================

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

  Map<String, dynamic> toJson() => {
    'technician_id': technicianId,
    'technician_service_id': technicianServiceId,
    'address_id': addressId,
    'time_slot_id': timeSlotId,
    'appointment_date': appointmentDate,
    'customer_note': customerNote,
    'images': images,
  };
}

class BookingResponse {
  final bool success;
  final String message;
  final Booking? data;

  BookingResponse({required this.success, required this.message, this.data});

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null ? Booking.fromJson(json['data']) : null,
    );
  }
}

class BookingListResponse {
  final bool success;
  final BookingListData data;

  BookingListResponse({required this.success, required this.data});

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    return BookingListResponse(
      success: json['success'] ?? false,
      data: BookingListData.fromJson(json['data']),
    );
  }
}

class BookingListData {
  final List<Booking> items;
  final PaginationMeta meta;

  BookingListData({required this.items, required this.meta});

  factory BookingListData.fromJson(Map<String, dynamic> json) {
    return BookingListData(
      items: (json['items'] as List)
          .map((item) => Booking.fromJson(item))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  int get totalPages => (total / limit).ceil();
}

// ==========================================
// 4. Calendar & Availability Models
// ==========================================

class PublicCalendarResponse {
  final String month;
  final List<PublicCalendarDay> days;

  PublicCalendarResponse({required this.month, required this.days});

  factory PublicCalendarResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return PublicCalendarResponse(
      month: data?['month'] ?? "",
      days: data?['days'] != null
          ? (data['days'] as List)
                .map((e) => PublicCalendarDay.fromJson(e))
                .toList()
          : [],
    );
  }
}

class PublicCalendarDay {
  final DateTime date;
  final String status;
  final int totalSlots;
  final int bookedSlots;
  final int availableSlots;
  final List<TimeSlot> timeSlots;
  final List<BookingDetail> bookings;

  PublicCalendarDay({
    required this.date,
    required this.status,
    required this.totalSlots,
    required this.bookedSlots,
    required this.availableSlots,
    required this.timeSlots,
    required this.bookings,
  });

  factory PublicCalendarDay.fromJson(Map<String, dynamic> json) {
    return PublicCalendarDay(
      date: TimeParser.parse(json['date']),
      status: json['status'] ?? '',
      totalSlots: json['total_slots'] ?? 0,
      bookedSlots: json['booked_slots'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      timeSlots: (json['time_slots'] as List<dynamic>? ?? [])
          .map((e) => TimeSlot.fromJson(e))
          .toList(),
      bookings: (json['bookings'] as List<dynamic>? ?? [])
          .map((e) => BookingDetail.fromJson(e))
          .toList(),
    );
  }
}

class TimeSlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool isBooked;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.isBooked,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isActive: json['is_active'] ?? false,
      isBooked: json['is_booked'] ?? false,
    );
  }
}

class BookingDetail {
  final int id;
  final String bookingNumber;
  final int timeSlotId;
  final String serviceName;
  final String pricingType;
  final double? quotedPriceMin;
  final double? quotedPriceMax;
  final DateTime appointmentDate;
  final String status;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String customerAvatar;
  final List<String> images;

  BookingDetail({
    required this.id,
    required this.bookingNumber,
    required this.timeSlotId,
    required this.serviceName,
    required this.pricingType,
    required this.quotedPriceMin,
    required this.quotedPriceMax,
    required this.appointmentDate,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatar,
    required this.images,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      id: json['id'] ?? 0,
      bookingNumber: json['booking_number'] ?? '',
      timeSlotId: json['time_slot_id'] ?? 0,
      serviceName: json['service_name'] ?? '',
      pricingType: json['pricing_type'] ?? '',
      quotedPriceMin: (json['quoted_price_min'] as num?)?.toDouble(),
      quotedPriceMax: (json['quoted_price_max'] as num?)?.toDouble(),
      appointmentDate: TimeParser.parse(json['appointment_date']),
      status: json['status'] ?? '',
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerAvatar: json['customer_avatar'] ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class TechnicianBooking {
  final int id;
  final String bookingNumber;
  final int timeSlotId;
  final String serviceName;
  final String pricingType;
  final int quotedPriceMin;
  final int quotedPriceMax;
  final String appointmentDate;
  final String status;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String customerAvatar;
  final List<String> images;
  final List<String> serviceImages;

  TechnicianBooking({
    required this.id,
    required this.bookingNumber,
    required this.timeSlotId,
    required this.serviceName,
    required this.pricingType,
    required this.quotedPriceMin,
    required this.quotedPriceMax,
    required this.appointmentDate,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatar,
    required this.images,
    required this.serviceImages,

  });

  factory TechnicianBooking.fromJson(Map<String, dynamic> json) {
    return TechnicianBooking(
      id: json['id'] ?? 0,
      bookingNumber: json['booking_number'] ?? "",
      timeSlotId: json['time_slot_id'] ?? 0,
      serviceName: json['service_name'] ?? "",
      pricingType: json['pricing_type'] ?? "",
      quotedPriceMin: json['quoted_price_min'] ?? 0,
      quotedPriceMax: json['quoted_price_max'] ?? 0,
      appointmentDate: json['appointment_date'] ?? "",
      status: json['status'] ?? "",
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? "",
      customerPhone: json['customer_phone'] ?? "",
      customerAvatar: json['customer_avatar'] ?? "",
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      serviceImages: (json['service_images'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    );
  }
}

class UpdateTechnicianCalendarResponse {
  final TechnicianCalendarData data;
  final String message;
  final bool success;

  UpdateTechnicianCalendarResponse({
    required this.data,
    required this.message,
    required this.success,
  });

  factory UpdateTechnicianCalendarResponse.fromJson(
      Map<String, dynamic> json) {
    return UpdateTechnicianCalendarResponse(
      data: TechnicianCalendarData.fromJson(json['data']),
      message: json['message'] ?? "",
      success: json['success'] ?? false,
    );
  }
}

class TechnicianCalendarData {
  final String date;
  final bool isOpen;

  TechnicianCalendarData({
    required this.date,
    required this.isOpen,
  });

  factory TechnicianCalendarData.fromJson(Map<String, dynamic> json) {
    return TechnicianCalendarData(
      date: json['date'] ?? "",
      isOpen: json['is_open'] ?? false,
    );
  }
}

class UpdateTimeSlotsResponse {
  final TimeSlotData data;
  final String message;
  final bool success;

  UpdateTimeSlotsResponse({
    required this.data,
    required this.message,
    required this.success,
  });

  factory UpdateTimeSlotsResponse.fromJson(Map<String, dynamic> json) {
    return UpdateTimeSlotsResponse(
      data: TimeSlotData.fromJson(json['data']),
      message: json['message'] ?? "",
      success: json['success'] ?? false,
    );
  }
}

class TimeSlotData {
  final String date;
  final bool isDefault;
  final List<TimeSlot> timeSlots;

  TimeSlotData({
    required this.date,
    required this.isDefault,
    required this.timeSlots,
  });

  factory TimeSlotData.fromJson(Map<String, dynamic> json) {
    return TimeSlotData(
      date: json['date'] ?? "",
      isDefault: json['is_default'] ?? false,
      timeSlots: (json['time_slots'] as List<dynamic>? ?? [])
          .map((e) => TimeSlot.fromJson(e))
          .toList(),
    );
  }
}


