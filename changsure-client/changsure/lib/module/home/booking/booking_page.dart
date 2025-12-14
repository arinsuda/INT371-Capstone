import 'package:changsure/core/header.dart';
import 'package:changsure/module/home/booking/section/address_card.dart';
import 'package:changsure/module/home/booking/section/booking_card.dart';
import 'package:changsure/module/home/booking/section/information_section.dart';
import 'package:changsure/module/home/booking/section/payment_card.dart';
import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../../../mockDB/technician.dart';
import 'booking_address.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: [
            Header(header: "จองบริการ"),
            Container(height: 24, color: AppColors.primaryBGHover),
            AddressCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingAddress()),
                );
              },
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            BookingCard(
              technician: Technician(
                firstName: "สมชาย",
                lastName: "รักชาติ",
                avatar: "assets/image/Technician.png",
                distance: 2.0,
                rating: 4.9,
                jobsCompleted: 34,
                price: 1000,
                tags: [
                  {
                    "icon": "assets/icons/top_service.png",
                    "text": "Top Service",
                  },
                  {
                    "icon": "assets/icons/changSure_rec.png",
                    "text": "ChangSure Recommend",
                  },
                ],
                category: "ทาสี",
                categoryTags: ["Top Service", "ChangSure Recommend"],
              ),
              service: Service(
                id: 1,
                serviceName: "บริการทาสีภายใน เกรดอัลตร้าพรีเมียม",
                price: 400,
                quantity: 1,
                image: "assets/image/clean1.png",
              ),
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            PaymentCard(),
            Container(height: 24, color: AppColors.primaryBGHover),
            InformationCard(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ สำคัญมาก
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

              decoration: BoxDecoration(
                color: AppColors.colorWarning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 18,
                    color: Color(0xFFAD6800),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      "เพื่อความปลอดภัยในการให้บริการ กรุณาเก็บทรัพย์สินที่มีค่าของท่าน "
                      "ไม่ทิ้งไว้บริเวณพื้นที่ให้บริการ หากเกิดความสูญหาย บริษัทขอสงวนสิทธิ์ไม่รับผิดชอบใด ๆ",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAD6800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    text: "ยกเลิก",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: "ยืนยัน",
                    onPressed: () {},
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
