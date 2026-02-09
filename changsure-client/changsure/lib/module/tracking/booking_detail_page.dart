import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/booking/booking_model.dart';
import '../../data/models/users/users_model.dart';
import '../../state/booking_provider.dart';
import '../../state/user_provider.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายละเอียดการจอง',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: bookingAsync.when(
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // Address Section
                _buildAddressSection(booking),

                const SizedBox(height: 12),

                // Show Customer for Technician, Show Technician for Customer
                isTechnician
                    ? _buildCustomerSection(booking)
                    : _buildTechnicianSection(booking),

                const SizedBox(height: 12),

                // Service Info Section
                _buildServiceInfoSection(booking),

                const SizedBox(height: 12),

                // Order Details Section
                _buildOrderDetailsSection(booking),

                const SizedBox(height: 12),

                // Additional Info Section
                _buildAdditionalInfoSection(booking),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(context, booking, ref),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressSection(Booking booking) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ที่อยู่จัดส่ง',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.recordedAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianSection(Booking booking) {
    final technician = booking.technician;

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
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: technician?.avatarUrl != null
                ? NetworkImage(technician!.avatarUrl!)
                : null,
            child: technician?.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ช่าง: ${technician?.getFullName() ?? 'ไม่ระบุ'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (technician?.phoneNumber != null)
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement call functionality
                // final uri = Uri(scheme: 'tel', path: technician!.phoneNumber!);
                // launchUrl(uri);
              },
              icon: const Icon(Icons.phone, size: 16, color: AppColors.primary),
              label: const Text(
                'โทร',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
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

  Widget _buildServiceInfoSection(Booking booking) {
    final service = booking.technicianService?.service;
    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
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
                      style: const TextStyle(
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.primary,
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
    );
  }

  Widget _buildOrderDetailsSection(Booking booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 16),
          _buildDetailRow('หมายเลขบริการ', booking.bookingNumber),
          const SizedBox(height: 12),
          _buildDetailRow(
            'วิธีการชำระเงิน',
            booking.paymentMethod,
            valueColor: const Color(0xFFFF9800),
            hasLabel: true,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'วันที่จองบริการ',
            booking.createdAt != null
                ? _formatThaiDate(booking.createdAt!)
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
    Color? valueColor,
    bool hasLabel = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
        ),
        hasLabel
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลเพิ่มเติม',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (hasImages) ...[
            const SizedBox(height: 16),
            const Text(
              'รูปภาพหน้างาน',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: booking.images!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
            const Text(
              'รายละเอียดเพิ่มเติม',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              booking.customerNote,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
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
