import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking/booking_model.dart';
import '../../../state/booking_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'รายละเอียดงาน #$bookingId',
          style: const TextStyle(
            color: Color(0xFF0038A8),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text("เกิดข้อผิดพลาด: $err"),
              TextButton(
                onPressed: () => ref.refresh(bookingDetailProvider(bookingId)),
                child: const Text("ลองใหม่"),
              ),
            ],
          ),
        ),
        data: (booking) {
          return _buildContent(context, booking);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Booking data) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'th');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(data.status),
          const SizedBox(height: 16),

          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ข้อมูลการนัดหมาย",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0038A8),
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.calendar_today,
                  "วัน-เวลานัดหมาย",
                  dateFormat.format(data.appointmentDate),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on,
                  "สถานที่",
                  data.recordedAddress,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.person,
                  "รหัสช่าง",
                  "Technician #${data.technicianId}",
                ),
                if (data.customerNote != null &&
                    data.customerNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.note,
                    "หมายเหตุเพิ่มเติม",
                    data.customerNote!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (data.images != null && data.images!.isNotEmpty) ...[
            const Text(
              "รูปภาพประกอบ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.images!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data.images![index].imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildPriceRow("วิธีชำระเงิน", data.paymentMethod ?? "COD"),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ราคาประเมิน",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      data.finalPrice != null
                          ? "฿${NumberFormat("#,###").format(data.finalPrice)}"
                          : "รอประเมิน",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0038A8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status) {
      case 'PENDING':
        bgColor = const Color(0xFFFFF4E5);
        textColor = const Color(0xFFFF9800);
        statusText = "รอช่างรับงาน";
        icon = Icons.hourglass_empty;
        break;
      case 'ACCEPTED':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        statusText = "ช่างรับงานแล้ว";
        icon = Icons.check_circle;
        break;
      case 'IN_PROGRESS':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF2196F3);
        statusText = "กำลังดำเนินการ";
        icon = Icons.build;
        break;
      case 'CANCELLED':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFF44336);
        statusText = "ยกเลิกแล้ว";
        icon = Icons.cancel;
        break;
      case 'COMPLETED':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        statusText = "เสร็จสิ้น";
        icon = Icons.task_alt;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
        statusText = status;
        icon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "สถานะปัจจุบัน",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
