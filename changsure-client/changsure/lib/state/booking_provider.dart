import 'package:changsure/data/services/booking_service.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking/booking_model.dart';
import '../data/models/technician/technician_model.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

final createBookingProvider =
    FutureProvider.family<BookingResponse, BookingCreateRequest>((
      ref,
      req,
    ) async {
      final service = ref.read(bookingServiceProvider);
      final user = ref.read(userProvider);

      final token = user?.token;
      if (token == null || token.isEmpty) {
        throw Exception("No token, user not logged in");
      }

      return service.createBooking(req, token);
    });

final cancelBookingProvider = FutureProvider.family<BookingResponse, int>((
  ref,
  bookingId,
) async {
  final service = ref.read(bookingServiceProvider);
  final user = ref.read(userProvider);

  final token = user?.token;
  if (token == null || token.isEmpty) {
    throw Exception("No token, user not logged in");
  }

  return service.cancelBooking(token, bookingId);
});

final timeSlotServiceProvider = Provider((ref) => BookingService());

final timeSlotsProvider = FutureProvider<List<TimeSlot>>((ref) async {
  final service = ref.read(timeSlotServiceProvider);
  final user = ref.read(userProvider);

  final token = user?.token;

  if (token == null || token.isEmpty) {
    throw Exception("No token, user not logged in");
  }

  print("🔥 LOAD TIME SLOT TOKEN = $token");

  return service.getTimeSlots(token);
});

final bookingDetailProvider = FutureProvider.family<BookingData, int>((
  ref,
  bookingId,
) async {
  final service = ref.read(bookingServiceProvider);
  final user = ref.read(userProvider);

  final token = user?.token;
  if (token == null || token.isEmpty) {
    throw Exception("No token, user not logged in");
  }

  return service.getBookingDetail(token, bookingId);
});

final technicianCalendarProvider = FutureProvider.family<
    CalendarResponse,
    ({int technicianId, String month})>((ref, params) async {
  final service = ref.read(bookingServiceProvider);
  final user = ref.read(userProvider);

  final token = user?.token;
  if (token == null || token.isEmpty) {
    throw Exception("Not logged in");
  }

  return service.getTechnicianCalendar(
    token: token,
    technicianId: params.technicianId,
    month: params.month,
  );
});

