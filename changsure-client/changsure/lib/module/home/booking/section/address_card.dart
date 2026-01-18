import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/address_model.dart';

class AddressCard extends ConsumerWidget {
  final VoidCallback? onTap;
  final Function(int addressId) onAddressSelected;
  final AddressModel? address;

  const AddressCard({
    super.key,
    this.onTap,
    required this.onAddressSelected,
    required this.address,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Stack(
          children: [
            /// 🔹 Content หลัก
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // ซ้ายยังชิดบน
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),

                Expanded(
                  child: address == null
                      ? const Text(
                          "กรุณาเลือกที่อยู่",
                          style: TextStyle(fontSize: 16),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("-", style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              "${address!.combinedAddressInfo}\n",
                              // "${address!.subDistrict} ${address!.district} ${address!.province} ${address!.postalCode}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.colorTertiaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(width: 32), // เผื่อที่ให้ icon ขวา
              ],
            ),

            /// ➡️ ไอคอนขวา (ลอยกลางแนวตั้ง)
            const Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight, // ✅ กลางแนวตั้ง + ชิดขวา
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
