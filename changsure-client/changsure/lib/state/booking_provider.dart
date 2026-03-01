import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:collection/collection.dart';
import '../data/models/booking/booking_model.dart';
import '../data/services/booking_service.dart';
import '../core/constants/realtime_events.dart';
import 'user_provider.dart';
import 'notifications/realtime_provider.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

class BookingListNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          List<Booking>,
          ({String? status, int page})
        > {
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  Future<List<Booking>> build(({String? status, int page}) arg) async {
    _subscribeRealtime();
    ref.onDispose(() => _realtimeSub?.cancel());

    return _fetch();
  }

  Future<List<Booking>> _fetch() async {
    final service = ref.read(bookingServiceProvider);
    final user = ref.read(userProvider);
    final token = user?.token;

    if (token == null || user == null) throw Exception("User not logged in");

    if (user.role == UserRole.technician) {
      return service.getTechnicianBookings(
        token: token,
        technicianId: user.id,
        status: arg.status,
        page: arg.page,
      );
    } else {
      return service.getMyBookings(
        token: token,
        customerId: user.id,
        status: arg.status,
        page: arg.page,
      );
    }
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = ref.read(realtimeStreamProvider.stream).listen((event) {
      final type = event['type'] as String? ?? '';

      const triggerEvents = {
        RealtimeEvents.bookingCreated,
        RealtimeEvents.bookingAccepted,
        RealtimeEvents.bookingRejected,
        RealtimeEvents.bookingCancelled,
        RealtimeEvents.bookingCancelledByTech,
        RealtimeEvents.jobStarted,
        RealtimeEvents.jobCompleted,
        RealtimeEvents.bookingStatusChanged,
      };

      if (triggerEvents.contains(type)) {
        final data = event['data'] as Map<String, dynamic>? ?? {};
        final newStatus = (data['status'] as String? ?? '').toUpperCase();

        if (_shouldRefreshForStatus(newStatus)) {
          ref.invalidateSelf();
        }
      }
    });
  }

  bool _shouldRefreshForStatus(String newStatus) {
    final watchedStatuses = arg.status?.toUpperCase().split(',') ?? [];

    if (watchedStatuses.isEmpty) return true;

    if (watchedStatuses.contains(newStatus)) return true;

    return true;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final myBookingsProvider = AsyncNotifierProvider.autoDispose
    .family<BookingListNotifier, List<Booking>, ({String? status, int page})>(
      BookingListNotifier.new,
    );

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

      final targetDay = calendar.days.firstWhereOrNull((d) {
        final target = DateTime.parse(params.date);
        return d.date.year == target.year &&
            d.date.month == target.month &&
            d.date.day == target.day;
      });

      if (targetDay == null) return [];

      return targetDay.timeSlots.where((slot) => slot.isActive).toList();
    });

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, int>((
  ref,
  bookingId,
) async {
  final service = ref.watch(bookingServiceProvider);
  final user = ref.watch(userProvider);
  final token = user?.token;

  if (token == null || user == null) throw Exception("User not logged in");

  if (user.role == UserRole.technician) {
    return service.getTechnicianBookingDetail(
      token: token,
      technicianId: user.id,
      bookingId: bookingId,
    );
  } else {
    return service.getCustomerBookingDetail(
      token: token,
      customerId: user.id,
      bookingId: bookingId,
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

      if (token == null || token.isEmpty) throw Exception("User not logged in");

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

      if (token == null || user == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      return service.getTechnicianCalendar(
        token: token,
        technicianId: user.id,
        month: params.month,
      );
    });

final technicianCalendarByDateProvider = FutureProvider.autoDispose
    .family<List<TechnicianBooking>, ({String date})>((ref, params) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || user == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      return service.getTechnicianCalendarByDate(
        token: token,
        technicianId: user.id,
        date: params.date,
      );
    });

final updateTechnicianCalendarProvider = FutureProvider.autoDispose
    .family<UpdateTechnicianCalendarResponse, ({String date, bool isOpen})>((
      ref,
      params,
    ) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || user == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      return service.updateTechnicianCalendarByDate(
        token: token,
        technicianId: user.id,
        date: params.date,
        isOpen: params.isOpen,
      );
    });

final updateTechnicianTimeSlotProvider = FutureProvider.autoDispose
    .family<
      UpdateTimeSlotsResponse,
      ({String date, bool isDefault, List<int> timeSlotIds})
    >((ref, params) async {
      final service = ref.watch(bookingServiceProvider);
      final user = ref.watch(userProvider);
      final token = user?.token;

      if (token == null || user == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      return service.updateTechnicianCalendarByTimeslot(
        token: token,
        technicianId: user.id,
        date: params.date,
        isDefault: params.isDefault,
        timeSlotIds: params.timeSlotIds,
      );
    });

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
    final user = ref.read(userProvider);
    final token = user?.token;
    final customerId = user?.id;

    if (token == null || customerId == null) return null;

    final result = await _service.createBooking(req, token, customerId);
    ref.invalidate(myBookingsProvider);
    return result;
  }

  Future<void> cancelBooking({
    required int bookingId,
    String reason = "",
  }) async {
    if (_token == null || _user == null) return;

    await _service.cancelBooking(
      token: _token!,
      customerId: _user!.id,
      bookingId: bookingId,
      reason: reason,
    );

    ref.invalidate(myBookingsProvider);
    ref.invalidate(bookingDetailProvider(bookingId));
  }

  Future<void> updateBookingStatus({
    required int bookingId,
    required BookingAction action,
    String? reason,
  }) async {
    if (_token == null || _user == null) return;

    await _service.updateBookingStatus(
      token: _token!,
      technicianId: _user!.id,
      bookingId: bookingId,
      action: action,
      reason: reason,
    );

    ref.invalidate(myBookingsProvider);
    ref.invalidate(bookingDetailProvider(bookingId));
  }
}
