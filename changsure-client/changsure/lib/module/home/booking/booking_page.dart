import 'package:changsure/core/header.dart';
import 'package:changsure/module/home/booking/booking_success.dart';
import 'package:changsure/module/home/booking/section/address_card.dart';
import 'package:changsure/module/home/booking/section/address_list.dart';
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
  BookingDateResult? selectedBookingDate;

  int? selectedAddressId;

  Future<bool> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: [
            Header(
              header: "จองบริการ",
              onPressed: () async {
                final shouldExit = await _showExitConfirmDialog();
                if (shouldExit) {
                  Navigator.pop(context);
                }
              },
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            AddressCard(
              selectedAddressId: selectedAddressId,
              onTap: () async {
                final pickedId = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressList(
                      initialSelectedAddressId: selectedAddressId,
                    ),
                  ),
                );

                if (pickedId != null) {
                  setState(() => selectedAddressId = pickedId);
                }
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
              onDateSelected: (result) {
                setState(() {
                  selectedBookingDate = result;
                });
              },
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
                    onPressed: selectedBookingDate == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingSuccess(
                                  bookingDate: selectedBookingDate!,
                                ),
                              ),
                            );
                          },
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
              "ต้องการออกจากหน้านี้หรือไม่ ?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: Text(
                "ระบบจะไม่บันทึกข้อมูลที่คุณกรอกไว้ หากคุณออกจากหน้านี้",
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
                      "ออกจากหน้านี้",
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
