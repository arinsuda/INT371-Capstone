import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../data/models/users/users_model.dart';
import '../../../../state/user_provider.dart';

class AddressCard extends ConsumerWidget {
  final VoidCallback? onTap;
  final int? selectedAddressId;
  final int? provinceId;

  const AddressCard({super.key, this.onTap, this.selectedAddressId, this.provinceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    final addresses = user?.role == UserRole.technician
        ? user?.technicianProfile?.addresses
        : user?.addresses;

    final selectedAddress = (addresses == null || addresses.isEmpty)
        ? null
        : addresses.firstWhere(
            (a) => a.id == selectedAddressId,
            orElse: () => addresses.firstWhere(
              (a) => a.isPrimary == true,
              orElse: () => addresses.first,
            ),
          );

    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : "-";

    final rawPhone = user?.phone?.trim() ?? "";
    final displayPhone = rawPhone.isNotEmpty ? _formatThaiPhone(rawPhone) : "";

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
        child: Stack(
          children: [
            /// 🔹 Content หลัก
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // ซ้ายยังชิดบน
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),

                Expanded(
                  child: selectedAddress == null
                      ? Text(
                          "ยังไม่มีที่อยู่ กรุณาเพิ่มที่อยู่",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.colorTertiaryText,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                if (displayPhone.isNotEmpty)
                                  Text(
                                    displayPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.colorTertiaryText,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${selectedAddress.addressLine} "
                              "${selectedAddress.subDistrict} "
                              "${selectedAddress.district} "
                              "${selectedAddress.province} "
                              "${selectedAddress.postalCode}",
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

                const SizedBox(width: 32),
              ],
            ),

            const Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.primaryBorder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatThaiPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');

    // +66 → 0
    if (digits.startsWith('66')) {
      digits = '0${digits.substring(2)}';
    }

    // มือถือ 10 หลัก
    if (digits.length == 10 && digits.startsWith('0')) {
      return '${digits.substring(0, 3)}-'
          '${digits.substring(3, 6)}-'
          '${digits.substring(6)}';
    }

    // เบอร์บ้าน กทม 9 หลัก
    if (digits.length == 9 && digits.startsWith('0')) {
      return '${digits.substring(0, 2)}-'
          '${digits.substring(2, 5)}-'
          '${digits.substring(5)}';
    }

    return raw;
  }
}
