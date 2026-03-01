import 'package:changsure/data/models/booking/booking_model.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/data/services/booking_service.dart';
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
          // ปิด dialog ก่อน
          Navigator.of(dialogContext).pop();

          try {
            await ref
                .read(bookingControllerProvider.notifier)
                .updateBookingStatus(
                  bookingId: booking.id,
                  action: BookingAction.reject,
                  reason: "ติดงานอื่น",
                );
            // FIX: ลบ Navigator.pop(context) ออก
            // TrackingCard อยู่ใน ListView — ไม่ใช่หน้าที่ push มา
            // การ pop จะทำให้จอดำเพราะไม่มีหน้าให้กลับไป
            // provider (myBookingsProvider) จะ reload list ให้อัตโนมัติ
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
          TrackingSection(booking: booking),
          const SizedBox(height: 20),
          ServiceSection(
            booking: booking,
            onViewDetail: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookingDetailPage(bookingId: booking.id),
                ),
              );
            },
          ),

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
                    // FIX: ไม่ต้อง pop — list refresh อัตโนมัติจาก realtime
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
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: const Text(
          "ชำระเงิน",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
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
