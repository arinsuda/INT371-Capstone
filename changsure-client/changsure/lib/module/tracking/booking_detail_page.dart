import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/module/chat/chat_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/theme.dart';
import '../../data/models/booking/booking_model.dart';
import '../../data/models/chat/chat_helper.dart';
import '../../data/models/users/users_model.dart';
import '../../state/booking_provider.dart';
import '../../state/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:changsure/state/bottom_nav_provider.dart';

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

  Future<void> _showExitConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () async {
          Navigator.of(context).pop();

          try {
            await ref
                .read(bookingControllerProvider.notifier)
                .cancelBooking(booking.id, "User cancelled booking");

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("ยกเลิกการจองสำเร็จ")));

            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ยกเลิกการจองไม่สำเร็จ")),
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _showCancelConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () async {
          Navigator.of(context).pop();

          try {
            await ref
                .read(bookingControllerProvider.notifier)
                .cancelBooking(booking.id, "User cancelled booking");

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("ปฏิเสธการจองสำเร็จ")));

            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ปฏิเสธการจองสำเร็จไม่สำเร็จ")),
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _showTechnicianCancelDialog(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TechnicianWorkDialog(
        onConfirm: () async {
          Navigator.of(context).pop();

          try {
            await ref
                .read(bookingControllerProvider.notifier)
                .rejectBooking(booking.id, "Technician cancelled booking");

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ยกเลิกกการบริการสำเร็จ")),
            );

            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ยกเลิกกการบริการไม่สำเร็จ")),
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildCustomerCancelButton(
    BuildContext context,
    Booking booking,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: IntrinsicWidth(
          child: TertiaryButton(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 24, vertical: 4),
            text: "ยกเลิกการจอง",
            onPressed: () async {
              await _showExitConfirmDialog(context, ref, booking);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianCancelButton(
    BuildContext context,
    Booking booking,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: IntrinsicWidth(
          child: TertiaryButton(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 24, vertical: 4),
            text: "ยกเลิกการบริการ",
            onPressed: () async {
              await _showTechnicianCancelDialog(context, ref, booking);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianSection(
    Booking booking,
    WidgetRef ref,
    BuildContext context,
  ) {
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
                          children: [
                            Icon(
                              Icons.star_rate_rounded,
                              color: Color(0xFFFFC53D),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${technician?.ratingAvg ?? 0}",
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
                              "จำนวนงานที่รับ: ${technician?.totalJobs ?? 0} ",
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
                child: GestureDetector(
                  onTap: () {
                    final technician = booking.technician;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          bookingId: bookingId,
                          participantInfo: ChatParticipantInfo(
                            userId: technician?.id ?? 0,
                            name:
                                "${technician?.firstName ?? ''} ${technician?.lastName ?? ''}"
                                    .trim(),
                            avatarUrl: technician?.avatarUrl,
                          ),
                        ),
                      ),
                    );
                  },
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
                      children: [
                        SvgPicture.asset(
                          "assets/icons/chatIcon.svg",
                          width: 18,
                          height: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        const Text(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));
    final user = ref.watch(userProvider);
    final isTechnician = user?.role == UserRole.technician;

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
              padding: const EdgeInsets.symmetric(horizontal: 0),
              children: [
                Header(header: "รายละเอียดการจอง"),
                Container(height: 16, color: AppColors.primaryBGHover),
                _buildAddressSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),

                isTechnician
                    ? _buildCustomerSection(booking, context)
                    : _buildTechnicianSection(booking, ref, context),
                Container(height: 16, color: AppColors.primaryBGHover),

                _buildOrderDetailsSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),

                _buildAdditionalInfoSection(booking),
                Container(height: 16, color: AppColors.primaryBGHover),
                if (isTechnician && booking.status?.toUpperCase() == 'PENDING')
                  _buildPendingActionRow(context, booking, ref),

                if (isTechnician && booking.status?.toUpperCase() == 'ACCEPTED')
                  _buildTechnicianCancelButton(context, booking, ref),

                if (!isTechnician &&
                    [
                      'PENDING',
                      'ACCEPTED',
                    ].contains(booking.status?.toUpperCase()))
                  _buildCustomerCancelButton(context, booking, ref),
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

  Widget _buildCustomerSection(Booking booking, BuildContext context) {
    final service = booking.technicianService?.service;
    final customer = booking.customer;
    print(customer);
    print(booking);

    final imageUrl = service?.getFirstImage() ?? '';
    final timeSlot = booking.timeSlot;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
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
                            customer?.avatarUrl != null &&
                                customer!.avatarUrl!.isNotEmpty
                            ? Image.network(
                                customer.avatarUrl!,
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
                                  'คุณ ${customer?.firstName ?? ''} ${customer?.lastName ?? ''}',
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
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      final customer = booking.customer;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            bookingId: booking.id,
                            participantInfo: ChatParticipantInfo(
                              userId: customer?.id ?? 0,
                              name:
                                  "${customer?.firstName ?? ''} ${customer?.lastName ?? ''}"
                                      .trim(),
                              avatarUrl: customer?.avatarUrl,
                            ),
                          ),
                        ),
                      );
                    },
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

    final hasNote =
        booking.customerNote != null && booking.customerNote!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลเพิ่มเติม',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          /// ------------------ รูปภาพ ------------------
          const SizedBox(height: 16),
          const Text('รูปภาพหน้างาน'),
          const SizedBox(height: 8),

          if (hasImages)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: booking.images!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      booking.images![index].imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            )
          else
            const Text(
              "ไม่มีรูปภาพเพิ่มเติม",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
            ),

          /// ------------------ Note ------------------
          const SizedBox(height: 16),
          const Text('รายละเอียดเพิ่มเติม'),
          const SizedBox(height: 8),

          if (hasNote)
            Text(
              booking.customerNote!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
            )
          else
            const Text(
              "ไม่มีรายละเอียดเพิ่มเติม",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildPendingActionRow(
  BuildContext context,
  Booking booking,
  WidgetRef ref,
) {
  final controller = ref.read(bookingControllerProvider.notifier);

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return _CancelWorkDialog(
                    onConfirm: () async {
                      Navigator.of(dialogContext).pop(); // ปิด dialog ก่อน

                      await controller.rejectBooking(
                        booking.id,
                        "ไม่สะดวกรับงาน",
                      );

                      Navigator.pop(context); // กลับหน้าก่อนหน้า
                    },
                    onCancel: () {
                      Navigator.of(dialogContext).pop();
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text("ปฏิเสธ"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              controller.acceptBooking(booking.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 16, color: AppColors.primary),
            label: const Text(
              "รับงาน",
              style: TextStyle(color: AppColors.primary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBG,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

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
              "ต้องการยกเลิกการจองใช่หรือไม่ ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 280,
              child: Text(
                "คุณต้องการยกเลิกการจองครั้งนี้ใช่หรือไม่ หากยกเลิก ข้อมูลการจองของคุณจะไม่ถูกบันทึก",
                style: TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    text: "อยู่ต่อ",
                    onPressed: onCancel,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    fontSize: 14,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF5222D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: const Color(0xFFF5222D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onConfirm,
                    child: const Text(
                      "ยกเลิกการจอง",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            SizedBox(
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

class _TechnicianWorkDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _TechnicianWorkDialog({
    required this.onConfirm,
    required this.onCancel,
  });

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
              "ยืนยันการยกเลิกการให้บริการ? ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 280,
              child: Text(
                "คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการให้บริการงานนี้ หากยกเลิกแล้วระบบจะแจ้งลูกค้าทันที",
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
