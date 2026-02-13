import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/booking/booking_model.dart';

class TrackingSection extends StatelessWidget {
  final Booking booking;

  const TrackingSection({super.key, required this.booking});

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFF8E1);
      case 'ACCEPTED':
        return const Color(0xFFFFF7E6);
      case 'IN_PROGRESS':
        return const Color(0xFFE1EFFA);
      case 'WAITING_PAYMENT':
        return const Color(0xFFFFF7E6);
      case 'COMPLETED':
        return const Color(0xFFF6FFED);
      case 'REJECTED':
        return const Color(0xFFFFF1F0);
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFB300);
      case 'ACCEPTED':
        return const Color(0xFFFA8C16);
      case 'IN_PROGRESS':
        return const Color(0xFF1677FF);
      case 'WAITING_PAYMENT':
        return const Color(0xFFFA8C16);
      case 'COMPLETED':
        return const Color(0xFF52C41A);
      case 'REJECTED':
        return const Color(0xFFF5222D);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = booking.getStatusText();
    final status = booking.status;
    final isNewJob = booking.status == 'PENDING';

    int currentStep = 0;
    switch (status) {
      case 'PENDING':
        currentStep = 2;
        break;
      case 'ACCEPTED':
      case 'IN_PROGRESS':
        currentStep = 3;
        break;
      case 'WAITING_PAYMENT':
      case 'COMPLETED':
        currentStep = 4;
        break;
      default:
        currentStep = 1;
    }

    Color statusBgColor = _getStatusBgColor(status);
    Color statusTextColor = _getStatusTextColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNewJob) ...[
          Row(
            children: [
              Icon(Icons.work, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "คุณได้รับงานใหม่!",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!isNewJob)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusTextColor, width: 1),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "หมายเลขบริการ",
              style: TextStyle(color: AppColors.colorTertiaryText, fontSize: 14),
            ),
            Text(
              booking.bookingNumber,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildCustomStepper(currentStep),
      ],
    );
  }

  Widget _buildCustomStepper(int step) {
    final List<String> labels = [
      "จองบริการ",
      "รอช่างรับงาน",
      "ช่างกำลัง\nดำเนินการ",
      "ดำเนินการ\nเสร็จสิ้น",
    ];

    return Row(
      children: List.generate(labels.length, (index) {
        bool isCompleted = index < step;
        bool isCurrent = index == step - 1;
        bool isLast = index == labels.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : (index <= step - 1
                                ? AppColors.primary
                                : Colors.grey.shade200),
                    ),
                  ),

                  Icon(
                    Icons.circle,
                    size: 12,
                    color: (index <= step - 1)
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),

                  Expanded(
                    child: Container(
                      height: 2,
                      color: isLast
                          ? Colors.transparent
                          : (index < step - 1
                                ? AppColors.primary
                                : Colors.grey.shade200),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 30,
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: (index <= step - 1)
                        ? Colors.black
                        : const Color(0xFF9B9B9B),
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
