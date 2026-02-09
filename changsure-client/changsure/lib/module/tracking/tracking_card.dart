import 'package:changsure/data/models/booking/booking_model.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/module/tracking/booking_detail_page.dart';
import 'package:changsure/state/booking_provider.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isTechnician = user?.role == UserRole.technician;
    final controller = ref.read(bookingControllerProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
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
              // Navigate to booking detail page
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
              _buildTechnicianActions(context, controller),
          ] else ...[
            if (booking.status == 'WAITING_PAYMENT')
              const Center(child: Text("กรุณาชำระเงินผ่าน QR Code ของช่าง")),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicianActions(
    BuildContext context,
    BookingController controller,
  ) {
    switch (booking.status) {
      case 'PENDING':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context, controller),
                icon: const Icon(Icons.close, size: 16),
                label: const Text("ปฏิเสธ"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Colors.red, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.acceptBooking(booking.id),
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
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'ACCEPTED':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => controller.startJob(booking.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              "เริ่มปฏิบัติงาน",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      case 'IN_PROGRESS':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showCompleteConfirmDialog(context, controller),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "ดำเนินการเสร็จสิ้น",
              style: TextStyle(color: Colors.white),
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

  void _showCompleteConfirmDialog(
    BuildContext context,
    BookingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการดำเนินงานเสร็จสิ้น"),
        content: const Text(
          "คุณดำเนินการเสร็จเรียบร้อยแล้วใช่หรือไม่? ระบบจะพาคุณไปยังขั้นตอนการชำระเงินของลูกค้า",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              controller.completeJob(booking.id);
              Navigator.pop(context);
            },
            child: const Text("ยืนยัน"),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, BookingController controller) {
    controller.rejectBooking(booking.id, "ไม่สะดวกรับงาน");
  }
}
