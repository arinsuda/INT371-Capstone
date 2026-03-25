import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/module/tracking/widget/rating_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../data/models/booking/booking_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/users/users_model.dart';
import '../../../state/user_provider.dart';

class ServiceSection extends ConsumerWidget {
  final Booking booking;
  final VoidCallback? onViewDetail;

  const ServiceSection({super.key, required this.booking, this.onViewDetail});

  String _formatThaiDate(DateTime date) {
    final months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isCompleted = booking.status == 'COMPLETED';
    final isTechnician = user?.role == UserRole.technician;

    if (!isCompleted) {
      return _buildDefaultSection(context);
    }

    return isTechnician
        ? _buildCompletedTechSection(context)
        : _buildCompletedCusSection(context);
  }

  Widget _buildDefaultSection(BuildContext context) {
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceImage(imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    service?.serName ?? 'บริการ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.getPriceDisplay(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDateRow(timeSlot),
        const SizedBox(height: 16),
        if (onViewDetail != null) ...[
          _buildViewDetailButton("ดูรายละเอียดเพิ่มเติม"),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCompletedTechSection(BuildContext context) {
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;
    final date = booking.appointmentDate;
    String formatThaiDate(DateTime date) {
      final formatter = DateFormat('d MMM yy', 'th');
      return formatter.format(date);
    }

    final paidAmount = booking.finalPrice;
    final displayPrice = booking.getPriceDisplay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceImage(imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service?.serName ?? 'บริการ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price summary row
                  if (paidAmount != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatThaiDate(date),
                          style: TextStyle(
                            color: AppColors.colorTertiaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'ทั้งหมด:',
                              style: TextStyle(
                                color: AppColors.colorTertiaryText,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '฿${paidAmount.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ปุ่มดูรายละเอียด
        if (onViewDetail != null) ...[
          _buildViewDetailButton("ดูสรุปค่าบริการ"),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCompletedCusSection(BuildContext context) {
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;
    final date = booking.appointmentDate;
    String formatThaiDate(DateTime date) {
      final formatter = DateFormat('d MMM yy', 'th');
      return formatter.format(date);
    }
    final hasReviewed = booking.reviewedAt != null;

    final paidAmount = booking.finalPrice;
    final displayPrice = booking.getPriceDisplay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  booking.technician?.avatarUrl != null &&
                      booking.technician!.avatarUrl!.isNotEmpty
                  ? NetworkImage(booking.technician!.avatarUrl!)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              "คุณ ${booking.technician!.firstName} ${booking.technician!.lastName}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rate_rounded,
                  color: Color(0xFFFFC53D),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  "${booking.technician!.ratingAvg}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  " / 5",
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: AppColors.colorStroke),
        const SizedBox(height: 10),

        // Service row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceImage(imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service?.serName ?? 'บริการ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price summary row
                  if (paidAmount != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatThaiDate(date),
                          style: TextStyle(
                            color: AppColors.colorTertiaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'ทั้งหมด:',
                              style: TextStyle(
                                color: AppColors.colorTertiaryText,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '฿${paidAmount.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TertiaryButton(
                text: "รับบริการอีกครั้ง",
                onPressed: () {},
                padding: EdgeInsets.symmetric(vertical: 4),
                fontSize: 14,
                borderRadius: 12,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                text: hasReviewed ? "ให้คะแนนแล้ว" : "ให้คะแนน",
                onPressed: hasReviewed
                    ? null // ❌ disabled
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewPage(
                        serviceImage: service!.imageUrls,
                        serviceName: service.serName,
                        bookingId: booking.id,
                      ),
                    ),
                  );
                },
                padding: EdgeInsets.symmetric(vertical: 4),
                fontSize: 14,
                borderRadius: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── shared helpers ───────────────────────────────────────────────────────

  Widget _buildServiceImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.cleaning_services),
    );
  }

  Widget _buildDateRow(timeSlot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/calendar.svg", width: 18, height: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${_formatThaiDate(booking.appointmentDate)}, ${timeSlot?.getTimeRange() ?? ''}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailButton(String label) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: onViewDetail,
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.colorStroke, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
