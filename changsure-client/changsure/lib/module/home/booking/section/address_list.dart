import 'package:changsure/core/button/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/header.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/users/users_model.dart';
import '../../../../state/bottom_nav_provider.dart';
import '../../../../state/user_provider.dart';

class AddressList extends ConsumerStatefulWidget {
  const AddressList({super.key});

  @override
  ConsumerState<AddressList> createState() => _AddressListState();
}

class _AddressListState extends ConsumerState<AddressList> {
  int? selectedAddressId;

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Header(
                header: "เลือกที่อยู่",
                onPressed: () {
                  Navigator.pop(context, selectedAddressId);
                },
              ),
            ),

            // 📜 List
            Expanded(
              child: Container(
                color: AppColors.primaryBGHover,
                child: addresses == null
                    ? const Center(child: CircularProgressIndicator())
                    : addresses.isEmpty
                    ? const Center(child: Text("ยังไม่มีที่อยู่"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          final isLast = index == addresses.length - 1;

                          return Column(
                            children: [
                              // 🧾 Card
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    selectedAddressId = addr.id;
                                  });

                                  if (addr.isPrimary != true) {
                                    if (user!.role == UserRole.customer) {
                                      await ref
                                          .read(userProvider.notifier)
                                          .saveCustomerAddress(
                                            id: addr.id,
                                            houseNumber: addr.houseNumber,
                                            subDistrict: addr.subDistrict,
                                            district: addr.district,
                                            province: addr.province,
                                            zipCode: addr.postalCode,
                                            provinceId: null,
                                            lat: addr.latitude,
                                            lng: addr.longitude,
                                          );
                                    } else {
                                      await ref
                                          .read(userProvider.notifier)
                                          .saveTechnicianAddress(
                                            id: addr.id,
                                            houseNumber: addr.houseNumber,
                                            subDistrict: addr.subDistrict,
                                            district: addr.district,
                                            province: addr.province,
                                            zipCode: addr.postalCode,
                                            provinceId: null,
                                            lat: addr.latitude,
                                            lng: addr.longitude,
                                          );
                                    }
                                  }

                                  if (mounted) {
                                    Navigator.pop(context, addr.id);
                                  }
                                },
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.only(
                                    right: 18,
                                    left: 18,
                                    top: 24,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 🔘 Radio
                                      Icon(
                                        selectedAddressId == addr.id
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: AppColors.primary,
                                      ),

                                      const SizedBox(width: 12),

                                      // 📄 Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "ที่อยู่ ${index + 1}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const TextSpan(text: "  "),
                                                  const TextSpan(
                                                    text: "90992948",
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .colorTertiaryText,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              "${addr.combinedAddressInfo}\n"
                                              "${addr.subDistrict} ${addr.district} ${addr.province} ${addr.postalCode}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color:
                                                    AppColors.colorTertiaryText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ➖ Divider (ถ้าไม่ใช่อันสุดท้าย)
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.primaryBorder,
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),

      // ➕ Bottom Bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(color: Colors.white),
        child: SecondaryButton(
          text: "เพิ่มที่อยู่ใหม่",
          onPressed: () {},
          borderRadius: 10,
          padding: const EdgeInsets.symmetric(vertical: 6),
          icon: Icons.add_rounded,
        ),
      ),
    );
  }
}
