import 'package:changsure/data/models/users/users_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking/booking_model.dart';
import '../data/services/booking_service.dart';
import 'user_provider.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

final availableTimeSlotsProvider = FutureProvider.autoDispose
    .family<List<TimeSlot>, ({int technicianId, String date})>((
      ref,
      params,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || token.isEmpty) throw Exception("User not logged in");

      return service.getAvailableTimeSlots(
        token: token,
        technicianId: params.technicianId,
        date: params.date,
      );
    });

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, int>((
  ref,
  bookingId,
) async {
  final service = ref.watch(bookingServiceProvider);
  final user = ref.watch(userProvider);
  final token = user?.token;

  if (token == null || user == null) {
    throw Exception("User not logged in");
  }

  if (user.role == UserRole.technician) {
    return service.getTechnicianBookingDetail(
      token: token,
      bookingId: bookingId,
    );
  } else {
    return service.getCustomerBookingDetail(token: token, bookingId: bookingId);
  }
});

final technicianCalendarProvider = FutureProvider.autoDispose
    .family<CalendarResponse, ({int technicianId, String month})>((
      ref,
      params,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || token.isEmpty) throw Exception("User not logged in");

      return service.getTechnicianCalendar(
        token: token,
        technicianId: params.technicianId,
        month: params.month,
      );
    });

final myBookingsProvider = FutureProvider.autoDispose
    .family<List<Booking>, ({String? status, int page})>((ref, params) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || user == null) throw Exception("User not logged in");

      if (user.role == UserRole.technician) {
        return service.getTechnicianBookings(
          token: token,
          status: params.status,
          page: params.page,
        );
      } else {
        return service.getMyBookings(
          token: token,
          status: params.status,
          page: params.page,
        );
      }
    });

final bookingControllerProvider =
    AsyncNotifierProvider.autoDispose<BookingController, void>(
      BookingController.new,
    );

class BookingController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<BookingResponse?> createBooking(BookingCreateRequest req) async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;

    if (token == null) {
      state = AsyncValue.error("User not logged in", StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      return await service.createBooking(req, token);
    });

    state = result.hasError
        ? AsyncValue.error(result.error!, result.stackTrace!)
        : const AsyncValue.data(null);

    return result.value;
  }

  Future<void> cancelBooking(int bookingId, String reason) async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;
    if (token == null) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await service.cancelBooking(
        token: token,
        bookingId: bookingId,
        reason: reason,
      );
    });

    if (!state.hasError) {
      ref.invalidate(bookingDetailProvider(bookingId));
    }
  }

  Future<void> acceptBooking(int bookingId) async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;
    if (token == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => service.acceptBooking(token: token, bookingId: bookingId),
    );
    if (!state.hasError) ref.invalidate(myBookingsProvider);
  }

  Future<void> rejectBooking(int bookingId, String reason) async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;
    if (token == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => service.rejectBooking(
        token: token,
        bookingId: bookingId,
        reason: reason,
      ),
    );
    if (!state.hasError) ref.invalidate(myBookingsProvider);
  }

  Future<void> startJob(int bookingId) async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;
    if (token == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => service.startJob(token: token, bookingId: bookingId),
    );
    if (!state.hasError) ref.invalidate(myBookingsProvider);
  }

  Future<void> completeJob(int bookingId) async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;
    if (token == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => service.completeJob(token: token, bookingId: bookingId),
    );
    if (!state.hasError) ref.invalidate(myBookingsProvider);
  }
}
