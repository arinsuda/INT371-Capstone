import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/theme.dart';
import '../../../../../../data/models/booking/booking_model.dart';

class ServiceCard extends StatelessWidget {
  final TechnicianBooking booking;
  final DateTime selectedDate;

  const ServiceCard({
    super.key,
    required this.booking,
    required this.selectedDate,
  });

  String getTimeSlotDisplay(int timeSlotId) {
    switch (timeSlotId) {
      case 1:
        return "09.00 - 12.00";
      case 2:
        return "13.00 - 16.00";
      case 3:
        return "17.00 - 20.00";
      default:
        return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
    DateFormat('d MMMM yyyy', 'th_TH').format(selectedDate);

    final timeText =
    getTimeSlotDisplay(booking.timeSlotId);

    final priceFormat = NumberFormat("#,###", "th_TH");

    final minPrice = booking.quotedPriceMin ?? 0;
    final maxPrice = booking.quotedPriceMax;

    String priceText;

    if (maxPrice != null && maxPrice > minPrice) {
      priceText =
      "฿${priceFormat.format(minPrice)} - ${priceFormat.format(maxPrice)}";
    } else {
      priceText = "฿${priceFormat.format(minPrice)}";
    }

    final imageUrl = (booking.serviceImages?.isNotEmpty ?? false)
        ? booking.serviceImages!.first
        : null;

    print(booking.serviceImages);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              /// ❗ รูปภาพคงเดิมตามที่คุณบอก
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primaryBorder,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),


              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName ?? "-",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/calendar.svg",
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "$formattedDate, $timeText",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.primaryText,
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
}
