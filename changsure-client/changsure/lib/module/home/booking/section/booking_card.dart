import 'package:changsure/module/home/booking/section/booking_calendar.dart';
import 'package:changsure/module/profile/technician/owner/activities/shared/constants/activity_constants.dart';

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

class BookingDateResult {
  final DateTime day;
  final String time;

  BookingDateResult({required this.day, required this.time});
}

class BookingCard extends StatefulWidget {
  final Technician technician;
  final Service service;
  final Function(BookingDateResult) onDateSelected;
  final bool readOnly;
  final BookingDateResult? initialDate;

  const BookingCard({
    super.key,
    required this.technician,
    required this.service,
    required this.onDateSelected,
    this.readOnly = false,
    this.initialDate,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  BookingDateResult? bookingDate;

  String _formatBookingDate(DateTime day, String time) {
    final thaiMonths = [
      '',
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

    return '${day.day} ${thaiMonths[day.month]} ${day.year}, $time';
  }

  String _toActivityCategoryKey(String shortName) {
    const map = {
      "ทาสี": "งานทาสี",
      "การประปา": "งานประปา",
      "ประปา": "งานประปา",
      "การไฟฟ้า": "งานไฟฟ้า",
      "ไฟฟ้า": "งานไฟฟ้า",
      "เครื่องใช้ไฟฟ้า": "งานเครื่องใช้ไฟฟ้า",
    };

    return map[shortName] ?? shortName;
  }

  Widget _buildCategoryTag(String shortName) {
    final categoryKey = _toActivityCategoryKey(shortName);
    final colors = ActivityConstants.getColors(categoryKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        shortName, // โชว์แบบสั้นเหมือนเดิม
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
    );
  }

  Widget _buildEditableDateView() {
    if (bookingDate == null) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingCalendar()),
          );

          if (result != null && result is BookingDateResult) {
            setState(() {
              bookingDate = result;
            });

            widget.onDateSelected(result);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    } else {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingCalendar(
                initialDay: bookingDate!.day,
                initialTime: bookingDate!.time,
              ),
            ),
          );

          if (result != null && result is BookingDateResult) {
            setState(() {
              bookingDate = result;
            });

            widget.onDateSelected(result);
          }
        },
        child: _buildDateDisplay(),
      );
    }
  }

  Widget _buildReadOnlyDateView() {
    if (bookingDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "ยังไม่ได้เลือกวันรับบริการ",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildDateDisplay();
  }

  Widget _buildSelectButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingCalendar()),
        );

        if (result != null && result is BookingDateResult) {
          setState(() {
            bookingDate = result;
          });

          widget.onDateSelected(result);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/icons/calendar.svg", width: 16, height: 16),
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
    );
  }

  Widget _buildEditableDate() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingCalendar(
              initialDay: bookingDate!.day,
              initialTime: bookingDate!.time,
            ),
          ),
        );

        if (result != null && result is BookingDateResult) {
          setState(() {
            bookingDate = result;
          });

          widget.onDateSelected(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const SizedBox(width: 12),
            Text(
              _formatBookingDate(bookingDate!.day, bookingDate!.time),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.create_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/calendar.svg", width: 18, height: 18),
          const SizedBox(width: 12),
          Text(
            _formatBookingDate(bookingDate!.day, bookingDate!.time),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyDate() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/calendar.svg", width: 18, height: 18),
          const SizedBox(width: 12),
          Text(
            _formatBookingDate(bookingDate!.day, bookingDate!.time),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    bookingDate = widget.initialDate; // ✅ รับค่าตั้งต้น
  }

  @override
  Widget build(BuildContext context) {
    final tech = widget.technician;

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
              Image.asset(widget.service.image, width: 50, height: 50),
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
                            widget.service.serviceName,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'x${widget.service.quantity}',
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
                      '฿${widget.service.price}',
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
            child: widget.readOnly
                ? (bookingDate == null
                      ? const SizedBox() // หรือไม่แสดงอะไร
                      : _buildReadonlyDate())
                : (bookingDate == null
                      ? _buildSelectButton()
                      : _buildEditableDate()),
          ),
        ],
      ),
    );
  }
}
