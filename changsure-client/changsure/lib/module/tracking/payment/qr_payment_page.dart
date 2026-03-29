import 'dart:async';
import 'package:changsure/core/constants/realtime_events.dart';
import 'package:changsure/module/tracking//payment/widgets/failed_view.dart';
import 'package:changsure/state/notifications/realtime_provider.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/button/primary_button.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../data/models/booking/booking_model.dart';
import '../../../state/payment_provider.dart';
import 'widgets/input_price_view.dart';
import './widgets/qr_display_view.dart';
import './widgets/success_view.dart';

class QRPaymentPage extends ConsumerStatefulWidget {
  final Booking booking;

  const QRPaymentPage({super.key, required this.booking});

  @override
  ConsumerState<QRPaymentPage> createState() => _QRPaymentPageState();
}

class _QRPaymentPageState extends ConsumerState<QRPaymentPage> {
  Timer? _expiryTimer;
  Duration _remaining = Duration.zero;
  WebViewController? _webViewController;

  @override
  void dispose() {
    _cancelCountdown();
    super.dispose();
  }

  void _cancelCountdown() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  void _startCountdown(DateTime expiresAt) {
    _cancelCountdown();

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = expiresAt.difference(DateTime.now());
      if (left.isNegative) {
        _cancelCountdown();
        ref.read(qrPaymentProvider.notifier).markExpired();
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  void _generateQR(double amount) {
    ref
        .read(qrPaymentProvider.notifier)
        .createPayment(bookingId: widget.booking.id, amount: amount);
  }

  Future<void> _fetchQRImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || !mounted) return;

      final html = _buildQRHtml(response.body);
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..loadHtmlString(html);

      setState(() => _webViewController = controller);
    } catch (_) {}
  }

  String _buildQRHtml(String svgBody) =>
      '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body {
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: white;
        width: 100vw;
        height: 100vh;
        overflow: hidden;
      }
      svg {
        width: 100% !important;
        height: auto !important;
        max-height: 100%;
      }
    </style>
  </head>
  <body>$svgBody</body>
</html>
''';

  bool _shouldConfirmExit(QRPaymentStatus status) =>
      status == QRPaymentStatus.ready || status == QRPaymentStatus.polling;

  Future<bool> _confirmExit(QRPaymentStatus status) async {
    if (!_shouldConfirmExit(status)) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExitConfirmDialog(),
    );
    if (confirmed != true) return false;

    _cancelCountdown();

    ref
        .read(qrPaymentProvider.notifier)
        .cancelPayment(bookingId: widget.booking.id)
        .ignore();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrPaymentProvider);

    ref.listen<QRPaymentState>(qrPaymentProvider, (_, next) {
      if (next.status == QRPaymentStatus.ready && next.qrData != null) {
        _startCountdown(next.qrData!.expiresAt);
        final qrUri = next.qrData!.qr?.qrCodeUri;
        if (qrUri != null) {
          _fetchQRImage(qrUri);
        }
      }
    });

    ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeStreamProvider, (
      _,
      next,
    ) {
      next.whenData((event) {
        final type = event['type'] as String?;
        final currentStatus = ref.read(qrPaymentProvider).status;

        // ✅ เพิ่ม loading และ idle เข้าไปด้วย เผื่อ event มาเร็ว
        final activeStatuses = {
          QRPaymentStatus.ready,
          QRPaymentStatus.polling,
          QRPaymentStatus.loading,
        };

        if (!activeStatuses.contains(currentStatus)) return;

        switch (type) {
          case RealtimeEvents.paymentSuccess:
            _cancelCountdown();
            ref.read(qrPaymentProvider.notifier).markSuccess();
            break;
          case RealtimeEvents.paymentFailed:
            _cancelCountdown();
            ref.read(qrPaymentProvider.notifier).markFailed();
            break;
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit(state.status) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(state.status),
        body: _buildBody(state),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(QRPaymentStatus status) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () async {
          if (await _confirmExit(status) && context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
      toolbarHeight: 80,
      title: Text(
        "ระบบชำระเงิน",
        style: const TextStyle(
          color: Color(0xFF003DAB),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(QRPaymentState state) {
    final isInputPhase =
        state.status == QRPaymentStatus.idle ||
        (state.status == QRPaymentStatus.loading && state.qrData == null);

    if (isInputPhase) {
      final isFixed = widget.booking.pricingType == 'FIXED';

      if (isFixed) {
        final fixedPrice = widget.booking.quotedPriceFixed ?? 0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.status == QRPaymentStatus.idle) {
            _generateQR(fixedPrice);
          }
        });

        return const Center(child: CircularProgressIndicator());
      }

      return InputPriceView(
        booking: widget.booking,
        isLoading: state.status == QRPaymentStatus.loading,
        onConfirm: _generateQR,
      );
    }

    return switch (state.status) {
      QRPaymentStatus.ready || QRPaymentStatus.polling => QRDisplayView(
        qrData: state.qrData!,
        remaining: _remaining,
        bookingNumber: widget.booking.bookingNumber,
        webViewController: _webViewController,
        technicianName: ref.watch(userProvider)?.technicianProfile != null
            ? '${ref.watch(userProvider)!.technicianProfile!.firstName} ${ref.watch(userProvider)!.technicianProfile!.lastName}'
            : null,
        technicianAvatar: ref.watch(userProvider)?.technicianProfile?.avatarUrl,
      ),
      QRPaymentStatus.success => SuccessView(amount: state.qrData?.amount ?? 0),
      QRPaymentStatus.expired => _StatusMessage(
        icon: Icons.timer_off_outlined,
        message: 'QR หมดอายุ กรุณาลองใหม่',
        actionLabel: 'ลองใหม่',
        onAction: () => ref.read(qrPaymentProvider.notifier).reset(),
      ),
      QRPaymentStatus.error => FailedView(
        errorMessage: state.errorMessage,
        onRetry: () => ref.read(qrPaymentProvider.notifier).reset(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ยกเลิกการชำระเงิน?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 280,
              child: Text(
                "QR Code จะถูกยกเลิกและคุณจะต้องสร้างใหม่อีกครั้ง",
                style: TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    text: "ยกเลิก",
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    fontSize: 14,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: "ยืนยัน",
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    padding: EdgeInsetsGeometry.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusMessage({
    required this.icon,
    required this.message,
    this.color = Colors.grey,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: color),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003DAB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
