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
  final CreateQRResponse? qrData;
  final String? errorMessage;

  const QRPaymentState({
    this.status = QRPaymentStatus.idle,
    this.qrData,
    this.errorMessage,
  });

  QRPaymentState copyWith({
    QRPaymentStatus? status,
    CreateQRResponse? qrData,
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

  QRPaymentNotifier(this._service, this._ref) : super(const QRPaymentState());

  String _getToken() {
    final token = _ref.read(userProvider)?.token;
    if (token == null || token.isEmpty) throw Exception('Unauthorized');
    return token;
  }

  Future<void> createQR({
    required int bookingId,
    required double amount,
  }) async {
    state = state.copyWith(status: QRPaymentStatus.loading);
    try {
      final qrData = await _service.createQR(
        token: _getToken(),
        bookingId: bookingId,
        amount: amount,
      );
      state = state.copyWith(status: QRPaymentStatus.ready, qrData: qrData);
    } catch (e) {
      state = state.copyWith(
        status: QRPaymentStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cancelQR({required int bookingId}) async {
    try {
      await _service.cancelQR(token: _getToken(), bookingId: bookingId);
    } catch (_) {}
  }

  void markExpired() {
    state = state.copyWith(status: QRPaymentStatus.expired);
  }

  void markFailed() {
    state = state.copyWith(status: QRPaymentStatus.failed);
  }

  void markSuccess() {
    state = state.copyWith(status: QRPaymentStatus.success);
    _ref.invalidate(myBookingsProvider);
  }

  void reset() {
    state = const QRPaymentState();
  }
}

final qrPaymentProvider =
    StateNotifierProvider.autoDispose<QRPaymentNotifier, QRPaymentState>((ref) {
      return QRPaymentNotifier(ref.watch(paymentServiceProvider), ref);
    });
