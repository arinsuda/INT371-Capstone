import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/theme.dart';
import '../../../data/models/booking/booking_model.dart';

class ServiceSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isCompleted = booking.status == 'COMPLETED';

    return isCompleted
        ? _buildCompletedSection(context)
        : _buildDefaultSection(context);
  }

  Widget _buildDefaultSection(BuildContext context) {
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;

    return Column(
      children: [
        Row(
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
          _buildViewDetailButton(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCompletedSection(BuildContext context) {
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;

    final paidAmount = booking.finalPrice;
    final displayPrice = booking.getPriceDisplay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หมายเลขบริการ
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'หมายเลขบริการ',
              style: TextStyle(
                color: AppColors.colorTertiaryText,
                fontSize: 13,
              ),
            ),
            Text(booking.bookingNumber, style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.colorStroke, height: 1),
        const SizedBox(height: 12),

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
                ],
              ),
            ),
            // ราคาขวามือ
            if (paidAmount != null)
              Text(
                '฿${paidAmount.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(color: AppColors.colorStroke, height: 1),
        const SizedBox(height: 8),

        // Price summary row
        if (paidAmount != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ทั้งหมด',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '฿${paidAmount.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ปุ่มดูรายละเอียด
        if (onViewDetail != null) ...[
          _buildViewDetailButton(),
          const SizedBox(height: 12),
        ],
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
              width: 60,
              height: 60,
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

  Widget _buildViewDetailButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: onViewDetail,
        label: const Text(
          "ดูรายละเอียดเพิ่มเติม",
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.colorStroke, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
