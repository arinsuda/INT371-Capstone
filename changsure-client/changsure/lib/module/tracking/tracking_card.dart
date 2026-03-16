import 'package:changsure/data/models/booking/booking_model.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/services/booking_service.dart';
import 'package:changsure/module/payment/qr_payment_page.dart';
import 'package:changsure/module/tracking/booking_detail_page.dart';
import 'package:changsure/state/booking_provider.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/button/primary_button.dart';
import '../../core/button/tertiary_button.dart';
import 'widget/service_section.dart';
import 'widget/tracking_section.dart';
import '../../core/theme.dart';

class TrackingCard extends ConsumerWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetail;

  const TrackingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onViewDetail,
  });

  Future<void> _showCancelConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CancelWorkDialog(
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          try {
            await ref
                .read(bookingControllerProvider.notifier)
                .updateBookingStatus(
                  bookingId: booking.id,
                  action: BookingAction.reject,
                  reason: "ติดงานอื่น",
                );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
            }
          }
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isTechnician = user?.role == UserRole.technician;
    final isCompleted = booking.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isCompleted)
            _buildCompletedHeader()
          else
            TrackingSection(booking: booking),

          const SizedBox(height: 20),

          ServiceSection(
            booking: booking,
            onViewDetail: () {
              if (isCompleted) {
                if (isTechnician) {
                  _showPaymentSummarySheet(
                    context,
                    booking.id,
                    booking.bookingNumber,
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingDetailPage(bookingId: booking.id),
                    ),
                  );
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingDetailPage(bookingId: booking.id),
                  ),
                );
              }
            },
          ),

          if (!isCompleted) ...[
            if (isTechnician) ...[
              const SizedBox(height: 12),
              if (booking.status == 'WAITING_PAYMENT')
                _buildClientPaymentAction(context)
              else
                _buildTechnicianActions(context, ref),
            ] else ...[
              if (booking.status == 'WAITING_PAYMENT')
                const Center(child: Text("กรุณาชำระเงินผ่าน QR Code ของช่าง")),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FFED),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF52C41A), width: 1),
        ),
        child: const Text(
          'ดำเนินการเสร็จสิ้น',
          style: TextStyle(
            color: Color(0xFF52C41A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianActions(BuildContext context, WidgetRef ref) {
    switch (booking.status) {
      case 'PENDING':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showCancelConfirmDialog(context, ref, booking),
                icon: const Icon(Icons.close, size: 16),
                label: const Text("ปฏิเสธ"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Colors.red, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(bookingControllerProvider.notifier)
                        .updateBookingStatus(
                          bookingId: booking.id,
                          action: BookingAction.accept,
                        );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                icon: const Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  "รับงาน",
                  style: TextStyle(color: AppColors.primary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBG,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.primary, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'ACCEPTED':
        return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF003EB3).withOpacity(0.9),
                  const Color(0xFF003EB3),
                ],
                stops: const [0.12, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(bookingControllerProvider.notifier)
                      .updateBookingStatus(
                        bookingId: booking.id,
                        action: BookingAction.start,
                      );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "เริ่มปฏิบัติงาน",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

      case 'IN_PROGRESS':
        return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBG.withOpacity(0.8),
                  AppColors.primaryBG,
                ],
                stops: const [0.12, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder, width: 1),
            ),
            child: ElevatedButton(
              onPressed: () => _showCompleteConfirmDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "ดำเนินการเสร็จสิ้น",
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientPaymentAction(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QRPaymentPage(booking: booking)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: const Text(
          'ชำระเงิน',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showPaymentSummarySheet(
    BuildContext context,
    int bookingId,
    String fallbackBookingNumber,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PaymentSummarySheet(
          bookingId: bookingId,
          fallbackBookingNumber: fallbackBookingNumber,
        );
      },
    );
  }

  void _showCompleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "ยืนยันการดำเนินงานเสร็จสิ้น",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "คุณดำเนินการเสร็จเรียบร้อยแล้วใช่หรือไม่?\n"
                  "หากยืนยัน ระบบจะพาคุณไปยังขั้นตอนการชำระเงินของลูกค้า และสถานะงานจะไม่สามารถแก้ไขได้อีก",
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TertiaryButton(
                        text: "ยกเลิก",
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: "ยืนยัน",
                        padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          try {
                            await ref
                                .read(bookingControllerProvider.notifier)
                                .updateBookingStatus(
                                  bookingId: booking.id,
                                  action: BookingAction.complete,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("งานเสร็จเรียบร้อย"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CancelWorkDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _CancelWorkDialog({required this.onConfirm, required this.onCancel});

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
              "ต้องการปฏิเสธงานนี้ใช่หรือไม่ ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 280,
              child: Text(
                "คุณแน่ใจหรือไม่ว่าต้องการปฏิเสธงานนี้ หากปฏิเสธแล้ว คุณจะไม่สามารถรับงานนี้ได้อีก",
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
                    onPressed: onCancel,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    fontSize: 14,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: "ยืนยัน",
                    onPressed: onConfirm,
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

class _PaymentSummarySheet extends ConsumerWidget {
  final int bookingId;
  final String fallbackBookingNumber;

  const _PaymentSummarySheet({
    required this.bookingId,
    required this.fallbackBookingNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: bookingAsync.when(
          loading: () => const SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, _) => SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'โหลดข้อมูลไม่สำเร็จ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          data: (b) {
            final service = b.technicianService?.service;
            final finalPrice = b.finalPrice;
            final feeAmount = b.feeAmount;
            final feeRate = b.feeRate;
            final netAmount = b.netAmount;
            final feeRatePct = feeRate != null
                ? '${(feeRate * 100).toStringAsFixed(0)}%'
                : '-';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── drag handle ─────────────────────────────────────
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // ── hero header with gradient ────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF003DAB), Color(0xFF1a5fd4)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'สรุปการชำระเงิน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        netAmount != null
                            ? '฿${netAmount.toStringAsFixed(0)}'
                            : '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ยอดที่คุณได้รับ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'เลขที่ ${b.bookingNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── breakdown rows ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      // service name
                      _infoTile(
                        icon: Icons.home_repair_service_rounded,
                        iconColor: Colors.blue.shade600,
                        iconBg: Colors.blue.shade50,
                        label: 'บริการ',
                        value: service?.serName ?? '-',
                      ),
                      const SizedBox(height: 10),

                      // price paid
                      _infoTile(
                        icon: Icons.payments_rounded,
                        iconColor: Colors.green.shade600,
                        iconBg: Colors.green.shade50,
                        label: 'ราคาบริการที่ลูกค้าจ่าย',
                        value: finalPrice != null
                            ? '฿${finalPrice.toStringAsFixed(0)}'
                            : '-',
                        valueColor: Colors.green.shade700,
                        valueBold: true,
                      ),
                      const SizedBox(height: 10),

                      // platform fee
                      _infoTile(
                        icon: Icons.percent_rounded,
                        iconColor: Colors.orange.shade600,
                        iconBg: Colors.orange.shade50,
                        label: 'ค่าธรรมเนียมแพลตฟอร์ม ($feeRatePct)',
                        value: feeAmount != null
                            ? '- ฿${feeAmount.toStringAsFixed(0)}'
                            : '-',
                        valueColor: Colors.orange.shade700,
                      ),

                      const SizedBox(height: 16),

                      // divider + net
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF003DAB).withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'ช่างได้รับสุทธิ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              netAmount != null
                                  ? '฿${netAmount.toStringAsFixed(0)}'
                                  : '-',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── action button ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailPage(bookingId: bookingId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('ดูรายละเอียดการจองทั้งหมด'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    Color valueColor = Colors.black87,
    bool valueBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
