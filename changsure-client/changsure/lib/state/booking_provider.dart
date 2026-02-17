import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:collection/collection.dart';
import '../data/models/booking/booking_model.dart';
import '../data/services/booking_service.dart';
import 'user_provider.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

final availableTimeSlotsProvider = Provider.autoDispose
    .family<List<TimeSlot>, ({int technicianId, String date, String month})>((
      ref,
      params,
    ) {
      final calendarAsync = ref.watch(
        publicCalendarProvider((
          technicianId: params.technicianId,
          month: params.month,
        )),
      );

      final calendar = calendarAsync.value;
      if (calendar == null) return [];

      final targetDay = calendar.days.firstWhereOrNull(
        (d) => d.date.toIso8601String().split('T').first == params.date,
      );

      if (targetDay == null) return [];

      // 🔥 Filter เฉพาะ slot ที่ active และยังไม่ถูกจอง
      return targetDay.timeSlots.where((slot) => slot.isActive).toList();
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

final publicCalendarProvider = FutureProvider.autoDispose
    .family<PublicCalendarResponse, ({int technicianId, String month})>((
      ref,
      params,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      return service.getPublicCalendar(
        token: token,
        technicianId: params.technicianId,
        month: params.month,
      );
    });

final technicianCalendarProvider = FutureProvider.autoDispose
    .family<PublicCalendarResponse, ({String month})>((ref, params) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      return service.getTechnicianCalendar(token: token, month: params.month);
    });

final technicianCalendarByDateProvider =
FutureProvider.autoDispose
    .family<List<TechnicianBooking>, ({String date})>(
      (ref, params) async {
    final service = ref.watch(bookingServiceProvider);
    final user = ref.watch(userProvider);
    final token = user?.token;

    if (token == null || token.isEmpty) {
      throw Exception("User not logged in");
    }

    return service.getTechnicianCalendarByDate(
      token: token,
      date: params.date,
    );
  },
);

final updateTechnicianCalendarProvider =
FutureProvider.autoDispose.family<
    UpdateTechnicianCalendarResponse,
    ({String date, bool isOpen})>(
      (ref, params) async {
    final service = ref.watch(bookingServiceProvider);
    final user = ref.watch(userProvider);
    final token = user?.token;

    if (token == null || token.isEmpty) {
      throw Exception("User not logged in");
    }


    return service.updateTechnicianCalendarByDate(
      token: token,
      date: params.date,
      isOpen: params.isOpen,
    );
  },
);

final updateTechnicianTimeSlotProvider =
FutureProvider.autoDispose.family<
    UpdateTimeSlotsResponse,
    ({String date, bool isDefault, List<int> timeSlotIds})>(
      (ref, params) async {
    final service = ref.watch(bookingServiceProvider);
    final user = ref.watch(userProvider);
    final token = user?.token;

    if (token == null || token.isEmpty) {
      throw Exception("User not logged in");
    }

    return service.updateTechnicianCalendarByTimeslot(
      token: token,
      date: params.date,
      isDefault: params.isDefault,
      timeSlotId: params.timeSlotIds,
    );
  },
);

/// 🔥 ACTION CONTROLLER — NO STATE
final bookingControllerProvider =
    NotifierProvider.autoDispose<BookingController, void>(
      BookingController.new,
    );

class BookingController extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  BookingService get _service => ref.read(bookingServiceProvider);

  UserModel? get _user => ref.read(userProvider);

  String? get _token => _user?.token;

  Future<BookingResponse?> createBooking(BookingCreateRequest req) async {
    if (_token == null) return null;
    return _service.createBooking(req, _token!);
  }

  Future<void> cancelBooking(int bookingId, String reason) async {
    if (_token == null) return;

    await _service.cancelBooking(
      token: _token!,
      bookingId: bookingId,
      reason: reason,
    );

    ref.invalidate(bookingDetailProvider(bookingId));
    ref.invalidate(myBookingsProvider);
  }

  Future<void> acceptBooking(int bookingId) async {
    if (_token == null) return;

    await _service.acceptBooking(token: _token!, bookingId: bookingId);

    ref.invalidate(myBookingsProvider);
  }

  Future<void> rejectBooking(int bookingId, String reason) async {
    if (_token == null) return;

    await _service.rejectBooking(
      token: _token!,
      bookingId: bookingId,
      reason: reason,
    );

    ref.invalidate(myBookingsProvider);
  }

  Future<void> startJob(int bookingId) async {
    if (_token == null) return;

    await _service.startJob(token: _token!, bookingId: bookingId);

    ref.invalidate(myBookingsProvider);
  }

  Future<void> completeJob(int bookingId) async {
    if (_token == null) return;

    await _service.completeJob(token: _token!, bookingId: bookingId);

    ref.invalidate(myBookingsProvider);
  }
}
