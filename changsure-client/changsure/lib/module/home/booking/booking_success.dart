import 'package:changsure/module/home/booking/section/booking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/header.dart';
import '../../../core/theme.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/booking/booking_model.dart';
import '../../../data/models/master_data_models.dart';
import '../../../state/booking_provider.dart';

class BookingSuccess extends ConsumerStatefulWidget {
  final BookingDateResult bookingDate;
  final Technician technician;
  final ServiceModel service;
  final BookingResponse response;
  final AddressModel? address;

  const BookingSuccess({
    super.key,
    required this.bookingDate,
    required this.technician,
    required this.service,
    required this.response,
    required this.address,
  });

  @override
  ConsumerState<BookingSuccess> createState() => _BookingSuccessState();
}

class _BookingSuccessState extends ConsumerState<BookingSuccess> {
  Future<void> _showExitConfirmDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () async {
          Navigator.of(context).pop(); // ปิด dialog ก่อน

          final bookingId = widget.response.data.id;

          try {
            final result = await ref.read(
              cancelBookingProvider(bookingId).future,
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? "ยกเลิกการจองสำเร็จ")),
            );

            Navigator.popUntil(
              context,
                  (route) => route.settings.name == '/serviceDetail',
            );
            debugPrint("CANCEL BOOKING Success");

          } catch (e) {
            debugPrint("CANCEL BOOKING ERROR => $e");
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ยกเลิกการจองไม่สำเร็จ")),
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }


  final List<String> images = [
    "assets/image/clean1.png",
    "assets/image/clean2.png",
  ];
  late String bookingDate;

  @override
  void initState() {
    super.initState();

    bookingDate = DateFormat(
      "d MMM yy",
      "th",
    ).format(widget.response.data.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.response.data.customerNote;
    debugPrint("IMAGES FROM API => ${widget.response.data.images}");
    final bookingId = widget.response.data.id;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: [
            Header(
              header: "จองบริการ",
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/image/bookingSuccess.png", width: 230),
                  const SizedBox(height: 10),
                  const Text(
                    "จองบริการเสร็จสิ้น",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 300,
                    child: Text(
                      "กรุณารอช่างรับงานซักครู่ ท่านสามารถติดตามสถานะ การดำเนินการได้ที่แถบเมนู ‘ติดตามสถานะ’",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(height: 24, color: AppColors.primaryBGHover),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "ธนชนก บรรจงจินดา",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "0982887376",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.colorTertiaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${widget.address!.combinedAddressInfo}\n",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            BookingCard(
              technician: widget.technician,
              service: widget.service,
              onDateSelected: (_) {},
              readOnly: true,
              initialDate: widget.bookingDate,
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "รายละเอียดคำสั่งซื้อ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text("หมายเลขบริการ"),
                      const Spacer(),
                      Text(
                        "8439849384",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text("วิธีการชำระเงิน"),
                      const Spacer(),
                      Image.asset(
                        'assets/icons/COD_logo.png',
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "เก็บเงินปลายทาง",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text("วันที่จองบริการ"),
                      const Spacer(),
                      Text(
                        bookingDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ข้อมูลเพิ่มเติม",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text("รูปภาพหน้างาน", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),

                  widget.response.data.images.isEmpty
                      ? const Text(
                          "ไม่มีรูปภาพเพิ่มเติม",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.colorTertiaryText,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.response.data.images.map((img) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                img.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 16),
                  const Text(
                    "รายละเอียดเพิ่มเติม",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (note == null || note.trim().isEmpty)
                        ? "ไม่มีรายละเอียดเพิ่มเติม"
                        : note,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ],
              ),
            ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    text: "ยกเลิกการจอง",
                    onPressed: () async {
                      await _showExitConfirmDialog();
                    },
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TertiaryButton(
                    text: "ติดตามสถานะ",
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => (),
                      //   ),
                      // );
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
                      "ยกเลิกกการจอง",
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
