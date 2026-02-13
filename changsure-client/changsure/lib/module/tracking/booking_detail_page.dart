import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/theme.dart';
import '../../data/models/booking/booking_model.dart';
import '../../data/models/users/users_model.dart';
import '../../state/booking_provider.dart';
import '../../state/user_provider.dart';
import 'package:intl/intl.dart';

class BookingDetailPage extends ConsumerWidget {
  final int bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

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
    return "${date.day} ${months[date.month - 1]} ${date.year + 543}"; // แสดงปี พ.ศ.
  }

  String formatThaiShortDate(DateTime date) {
    final formatter = DateFormat('d MMM yy', 'th_TH');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: bookingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(bookingDetailProvider(bookingId)),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
          data: (booking) {
            final user = ref.watch(userProvider);
            final isTechnician = user?.role == UserRole.technician;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                Header(header: "รายละเอียดการจอง"),
                Container(height: 16, color: AppColors.primaryBGHover),
                _buildAddressSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),

                isTechnician
                    ? _buildCustomerSection(booking)
                    : _buildTechnicianSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),

                _buildOrderDetailsSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),

                _buildAdditionalInfoSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),

                _buildActionButtons(context, booking, ref),
                Container(height: 8, color: AppColors.primaryBGHover),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IntrinsicWidth(
                      child: TertiaryButton(
                        text: "ยกเลิกการจอง",
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 24, vertical: 4),
                        onPressed: () {},
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

  Widget _buildAddressSection(Booking booking) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ที่อยู่จัดส่ง',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.recordedAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianSection(Booking booking) {
    final technician = booking.technician;
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey.shade200,
                    child: ClipOval(
                      child:
                          technician?.avatarUrl != null &&
                              technician!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              technician.avatarUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 28);
                              },
                            )
                          : const Icon(Icons.person, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'คุณ ${technician?.firstName ?? ''} ${technician?.lastName ?? ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF1677FF),
                              size: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(
                              Icons.star_rate_rounded,
                              color: Color(0xFFFFC53D),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "เลข",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              " / 5",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "|",
                              style: TextStyle(color: AppColors.colorStroke),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "จำนวนงานที่รับ: เลข",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/chatIcon.svg",
                        width: 18,
                        height: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "แชท",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.colorStroke, height: 1),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.cleaning_services),
                            ),
                    ),
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
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/calendar.svg",
                        width: 18,
                        height: 18,
                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(Booking booking) {
    // For technician view - show customer information
    // Parse customer name and phone from recordedAddress if available
    String customerInfo = 'ลูกค้า';
    String? customerPhone;

    // Try to extract phone number from recordedAddress
    final phoneRegex = RegExp(r'(\d{2,3})-?(\d{3})-?(\d{4})');
    final match = phoneRegex.firstMatch(booking.recordedAddress);
    if (match != null) {
      customerPhone = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerInfo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (customerPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    customerPhone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (customerPhone != null)
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement call functionality
                // final uri = Uri(scheme: 'tel', path: customerPhone);
                // launchUrl(uri);
              },
              icon: const Icon(Icons.phone, size: 16, color: Colors.green),
              label: const Text(
                'โทร',
                style: TextStyle(color: Colors.green, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsSection(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดคำสั่งซื้อ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('หมายเลขบริการ', booking.bookingNumber),
          const SizedBox(height: 8),
          _buildDetailRow(
            'วิธีการชำระเงิน',
            '',
            valueColor: const Color(0xFFFF9800),
            hasLabel: true,
            suffix: ' เก็บเงินปลายทาง',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'วันที่จองบริการ',
            booking.createdAt != null
                ? formatThaiShortDate(booking.createdAt!)
                : '-',
          ),
          if (booking.finalPrice != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'ราคาจริง',
              '฿${booking.finalPrice!.toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    String? suffix,
    Color? valueColor,
    bool hasLabel = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
        ),
        Row(
          children: [
            if (hasLabel)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/COD_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      suffix,
                      style: const TextStyle(
                        color: AppColors.colorTertiaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              )
            else
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.colorTertiaryText,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(Booking booking) {
    final hasImages = booking.images != null && booking.images!.isNotEmpty;
    final hasNote = booking.customerNote.isNotEmpty;

    if (!hasImages && !hasNote) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลเพิ่มเติม',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (hasImages) ...[
            const SizedBox(height: 16),
            const Text('รูปภาพหน้างาน', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: booking.images!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      child: Image.network(
                        booking.images![index].imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (hasNote) ...[
            const SizedBox(height: 16),
            const Text('รายละเอียดเพิ่มเติม', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              booking.customerNote,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Booking booking,
    WidgetRef ref,
  ) {
    final controller = ref.read(bookingControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final isTechnician = user?.role == UserRole.technician;

    // Only show action buttons for technicians with PENDING status
    if (!isTechnician || booking.status != 'PENDING') {
      return const SizedBox.shrink();
    }
    // Only show action buttons for technicians with PENDING status
    if (!isTechnician || booking.status != 'PENDING') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                controller.rejectBooking(booking.id, "ไม่สะดวกรับงาน");
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'ปฏิเสธ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                controller.acceptBooking(booking.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'รับงาน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
