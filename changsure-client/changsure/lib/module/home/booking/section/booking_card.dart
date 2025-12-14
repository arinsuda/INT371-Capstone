import 'package:changsure/module/home/booking/section/booking_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme.dart';
import '../../../../mockDB/technician.dart';

class Service {
  final int id;
  final String serviceName;
  final int price;
  final int quantity;
  final String image;

  Service({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.quantity,
    required this.image,
  });
}

class BookingCard extends StatelessWidget {
  final Technician technician;
  final Service service;

  const BookingCard({
    super.key,
    required this.technician,
    required this.service,
  });

  Widget _buildCategoryTag(String name) {
    final colorMap = {
      "ทาสี": {
        "text": const Color(0xFFEB2F96),
        "background": const Color(0xFFFFF0F6),
        "border": const Color(0xFFFFADD2),
      },
      "การประปา": {
        "text": const Color(0xFF36CFC9),
        "background": const Color(0xFFE6FFFB),
        "border": const Color(0xFF87E8DE),
      },
      "การไฟฟ้า": {
        "text": const Color(0xFFFAAD14),
        "background": const Color(0xFFFFFBE6),
        "border": const Color(0xFFFFE58F),
      },
      "เครื่องใช้ไฟฟ้า": {
        "text": const Color(0xFF722ED1),
        "background": const Color(0xFFF9F0FF),
        "border": const Color(0xFFD3ADF7),
      },
    };

    final color = colorMap[name] ?? colorMap["ทาสี"]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color["background"],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color["border"]!, width: 1),
      ),
      child: Text(name, style: TextStyle(color: color["text"], fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tech = technician;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(tech.avatar),
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
                                'คุณ ${tech.firstName} ${tech.lastName}',
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
                            const Icon(
                              Icons.star_rate_rounded,
                              color: Color(0xFFFFC53D),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${tech.rating}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              " / 5",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "|",
                              style: TextStyle(color: AppColors.colorStroke),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "จำนวนงานที่รับ: ${tech.jobsCompleted}",
                              style: const TextStyle(
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
                child: _buildCategoryTag(tech.category),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Divider(color: AppColors.colorStroke, height: 1),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(service.image, width: 50, height: 50),
              const SizedBox(width: 12),

              SizedBox(
                width: MediaQuery.of(context).size.width - 120, // ✅ สำคัญ
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.serviceName,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'x${service.quantity}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿${service.price}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingCalendar()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/icons/calendar.svg",
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "เลือกวันรับบริการ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
