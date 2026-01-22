import 'package:changsure/data/services/booking_service.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking/booking_model.dart';

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
