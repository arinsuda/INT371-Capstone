import 'dart:async';
import 'package:changsure/data/models/payment/payment_model.dart';
import 'package:changsure/data/services/payment_service.dart';
import 'package:changsure/state/booking_provider.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

enum QRPaymentStatus {
  idle,
  loading,
  ready,
  polling,
  success,
  expired,
  failed,
  error,
}

class QRPaymentState {
  final QRPaymentStatus status;
  final CreatePaymentResponse? qrData;
  final String? errorMessage;

  const QRPaymentState({
    this.status = QRPaymentStatus.idle,
    this.qrData,
    this.errorMessage,
  });

  QRPaymentState copyWith({
    QRPaymentStatus? status,
    CreatePaymentResponse? qrData,
    String? errorMessage,
  }) {
    return QRPaymentState(
      status: status ?? this.status,
      qrData: qrData ?? this.qrData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QRPaymentNotifier extends StateNotifier<QRPaymentState> {
  final PaymentService _service;
  final Ref _ref;
  Timer? _pollTimer;

  QRPaymentNotifier(this._service, this._ref) : super(const QRPaymentState());

  String _getToken() {
    final token = _ref.read(userProvider)?.token;
    if (token == null || token.isEmpty) throw Exception('Unauthorized');
    return token;
  }

  Future<void> createPayment({
    required int bookingId,
    required double amount,
    String method = 'promptpay',
  }) async {
    state = state.copyWith(status: QRPaymentStatus.loading);
    try {
      final data = await _service.createPayment(
        token: _getToken(),
        bookingId: bookingId,
        amount: amount,
        method: method,
      );
      state = state.copyWith(status: QRPaymentStatus.ready, qrData: data);
      _startPolling(bookingId: bookingId, expiresAt: data.expiresAt);
    } catch (e) {
      state = state.copyWith(
        status: QRPaymentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _startPolling({required int bookingId, required DateTime expiresAt}) {
    _pollTimer?.cancel();
    state = state.copyWith(status: QRPaymentStatus.polling);

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (DateTime.now().isAfter(expiresAt)) {
        markExpired();
        return;
      }
      try {
        final result = await _service.checkPaymentStatus(
          token: _getToken(),
          bookingId: bookingId,
        );
        if (result.hasPaid) {
          markSuccess();
        }
      } catch (_) {}
    });
  }

  Future<void> cancelPayment({required int bookingId}) async {
    _pollTimer?.cancel();
    try {
      await _service.cancelPendingPayment(
        token: _getToken(),
        bookingId: bookingId,
      );
    } catch (_) {}
    state = const QRPaymentState();
  }

  void markExpired() {
    _pollTimer?.cancel();
    state = state.copyWith(status: QRPaymentStatus.expired);
  }

  void markFailed() {
    _pollTimer?.cancel();
    state = state.copyWith(status: QRPaymentStatus.failed);
  }

  void markSuccess() {
    _pollTimer?.cancel();
    state = state.copyWith(status: QRPaymentStatus.success);
    _ref.invalidate(myBookingsProvider);
  }

  void reset() {
    _pollTimer?.cancel();
    state = const QRPaymentState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final qrPaymentProvider =
    StateNotifierProvider.autoDispose<QRPaymentNotifier, QRPaymentState>((ref) {
      return QRPaymentNotifier(ref.watch(paymentServiceProvider), ref);
    });