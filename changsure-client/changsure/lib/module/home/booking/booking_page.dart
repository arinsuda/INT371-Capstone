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
import '../../../data/models/booking/booking_model.dart' hide Technician;
import '../../../data/models/master_data_models.dart';
import '../../../data/models/users/users_model.dart';
import '../../../state/booking_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/user_provider.dart';
import 'package:collection/collection.dart';

class BookingPage extends ConsumerStatefulWidget {
  final ServiceModel data;
  final Technician technician;
  final int? provinceId;

  const BookingPage({
    super.key,
    required this.data,
    required this.technician,
    this.provinceId,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  BookingDateResult? selectedBookingDate;
  int? selectedAddressId;
  int? selectedTimeSlotId;
  String? customerNote;
  List<String> images = [];
  bool _hasShownProvinceWarning = false;

  bool get isFormValid {
    return selectedBookingDate != null &&
        selectedAddressId != null &&
        selectedTimeSlotId != null &&
        isProvinceValid;
  }

  bool get isProvinceValid {
    final user = ref.read(userProvider);
    final addresses = user?.role == UserRole.technician
        ? user?.technicianProfile?.addresses
        : user?.addresses;

    final selectedAddress = addresses?.firstWhereOrNull(
      (a) => a.id == selectedAddressId,
    );

    if (widget.provinceId == null || selectedAddress == null) return true;

    return selectedAddress.provinceId == widget.provinceId;
  }

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
    final user = ref.watch(userProvider);
    final addresses = user?.role == UserRole.technician
        ? user?.technicianProfile?.addresses
        : user?.addresses;

    if (selectedAddressId == null &&
        addresses != null &&
        addresses.isNotEmpty) {
      final primary = addresses.where((a) => a.isPrimary == true).toList();
      if (primary.isNotEmpty) {
        selectedAddressId = primary.first.id;
      }
    }

    final selectedAddress = addresses?.firstWhereOrNull(
      (a) => a.id == selectedAddressId,
    );

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
            Container(
              height: !isProvinceValid ? 40 : 24,
              color: AppColors.primaryBGHover,
              child: !isProvinceValid
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: 18,
                        bottom: 0,
                        left: 18,
                      ),
                      child: Text(
                        "*ที่อยู่ที่เลือกอยู่นอกพื้นที่ให้บริการ กรุณาเลือกที่อยู่ใหม่",
                        style: TextStyle(
                          color: AppColors.colorError,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),

            AddressCard(
              selectedAddressId: selectedAddressId,
              onTap: () async {
                final pickedId = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressList(
                      initialSelectedAddressId: selectedAddressId,
                      provinceId: widget.provinceId,
                      allowSelect: true,
                    ),
                  ),
                );

                if (pickedId != null) {
                  setState(() {
                    selectedAddressId = pickedId;
                  });
                }
              },
              provinceId: widget.provinceId,
            ),

            Container(height: 24, color: AppColors.primaryBGHover),
            BookingCard(
              technician: widget.technician,
              service: widget.data,
              onDateSelected: (result) {
                setState(() {
                  selectedBookingDate = result;
                  selectedTimeSlotId = result.timeSlotId;
                });
              },
            ),
            Container(height: 24, color: AppColors.primaryBGHover),
            PaymentCard(),
            Container(height: 24, color: AppColors.primaryBGHover),
            InformationCard(
              onChanged: (note, pickedImages) {
                customerNote = note;
                images = pickedImages.map((e) => e.path).toList();
              },
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
                    onPressed: isFormValid
                        ? () async {
                            final date = selectedBookingDate!.day;

                            final formattedDate =
                                "${date.year.toString().padLeft(4, '0')}-"
                                "${date.month.toString().padLeft(2, '0')}-"
                                "${date.day.toString().padLeft(2, '0')}";



                            final req = BookingCreateRequest(
                              technicianId: widget.technician.id,
                              technicianServiceId: widget.data.id,
                              addressId: selectedAddressId!,
                              timeSlotId: selectedTimeSlotId!,
                              appointmentDate: formattedDate,
                              customerNote: customerNote?.isEmpty == true
                                  ? null
                                  : customerNote,
                              images: images,
                            );

                            debugPrint("=== BOOKING REQUEST ===");
                            debugPrint("technicianId: ${req.technicianId}");
                            debugPrint("technicianServiceId: ${req.technicianServiceId}");
                            debugPrint("addressId: ${req.addressId}");
                            debugPrint("timeSlotId: ${req.timeSlotId}");
                            debugPrint("appointmentDate: ${req.appointmentDate}");
                            debugPrint("customerNote: ${req.customerNote}");
                            debugPrint("images: ${req.images}");
                            debugPrint("=======================");

                            try {
                              final result = await ref
                                  .read(bookingControllerProvider.notifier)
                                  .createBooking(req);

                              debugPrint("BOOKING RESULT => $result");

                              if (result != null && result.success && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingSuccess(
                                      bookingDate: selectedBookingDate!,
                                      technician: widget.technician,
                                      service: widget.data,
                                      response: result,
                                      address: selectedAddress,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result?.message ?? "จองไม่สำเร็จ",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint("BOOKING ERROR => $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                              );
                            }
                          }
                        : null,
                    padding: EdgeInsetsGeometry.symmetric(vertical: 8),
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
