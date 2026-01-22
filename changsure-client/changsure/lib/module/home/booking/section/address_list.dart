import 'package:changsure/core/button/secondary_button.dart';
import 'package:changsure/core/profile/address.dart';
import 'package:changsure/data/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/header.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/users/users_model.dart';
import '../../../../state/user_provider.dart';

class AddressList extends ConsumerStatefulWidget {
  final int? initialSelectedAddressId;
  final int? provinceId;

  const AddressList({
    super.key,
    this.initialSelectedAddressId,
    this.provinceId,
  });

  @override
  ConsumerState<AddressList> createState() => _AddressListState();
}

class _AddressListState extends ConsumerState<AddressList> {
  int? selectedAddressId;

  @override
  void initState() {
    super.initState();
    selectedAddressId = widget.initialSelectedAddressId;
  }

  Future<void> _editAddress(AddressModel addr) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Address(
          addressId: addr.id,
          houseNumber: addr.houseNumber ?? '',
          subDistrict: addr.subDistrict ?? '',
          district: addr.district ?? '',
          province: addr.province ?? '',
          postCode: int.tryParse(addr.postalCode ?? '0') ?? 0,
          provinceId: addr.provinceId,
          districtId: addr.districtId,
          subDistrictId: addr.subDistrictId,
          initialLat: addr.latitude,
          initialLng: addr.longitude,
          onSave: (data) async {
            final houseNumber = (data['house_number'] ?? '').toString();
            final subDistrict = (data['sub_district'] ?? '').toString();
            final district = (data['district'] ?? '').toString();
            final province = (data['province'] ?? '').toString();
            final zipCode = (data['postal_code'] ?? '').toString();

            final provinceId = data['province_id'] as int?;
            final districtId = data['district_id'] as int?;
            final subDistrictId = data['sub_district_id'] as int?;

            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();

            if (user.role == UserRole.customer) {
              await ref
                  .read(userProvider.notifier)
                  .saveCustomerAddress(
                    id: addr.id,
                    houseNumber: houseNumber,
                    subDistrict: subDistrict,
                    district: district,
                    province: province,
                    zipCode: zipCode,
                    provinceId: provinceId,
                    districtId: districtId,
                    subDistrictId: subDistrictId,
                    lat: lat,
                    lng: lng,
                  );
            } else {
              await ref
                  .read(userProvider.notifier)
                  .saveTechnicianAddress(
                    id: addr.id,
                    houseNumber: houseNumber,
                    subDistrict: subDistrict,
                    district: district,
                    province: province,
                    zipCode: zipCode,
                    provinceId: provinceId,
                    districtId: districtId,
                    subDistrictId: subDistrictId,
                    lat: lat,
                    lng: lng,
                  );
            }
          },
          onDelete: (id) async {
            if (user.role == UserRole.customer) {
              await ref.read(userProvider.notifier).deleteCustomerAddress(id);
            } else {
              await ref.read(userProvider.notifier).deleteTechnicianAddress(id);
            }

            if (selectedAddressId == id) {
              setState(() => selectedAddressId = null);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final addresses = user?.role == UserRole.technician
        ? user?.technicianProfile?.addresses
        : user?.addresses;

    final raw = addresses ?? [];
    final displayAddresses = [...raw]..sort((a, b) => a.id.compareTo(b.id));
    displayAddresses.sort((a, b) {
      final ap = a.isPrimary == true ? 0 : 1;
      final bp = b.isPrimary == true ? 0 : 1;
      if (ap != bp) return ap - bp;
      return a.id.compareTo(b.id);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Header(
                header: "เลือกที่อยู่",
                onPressed: () {
                  Navigator.pop(context,selectedAddressId);
                },
              ),
            ),

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

                          final bool isSelectable =
                              widget.provinceId == null ||
                              addr.provinceId == widget.provinceId;

                          return Column(
                            children: [
                              InkWell(
                                onTap: isSelectable
                                    ? () async {
                                        // setState(() {¬
                                        //   selectedAddressId = addr.id;
                                        // });

                                        // if (addr.isPrimary != true) {
                                        //   if (user!.role == UserRole.customer) {
                                        //     await ref
                                        //         .read(userProvider.notifier)
                                        //         .saveCustomerAddress(
                                        //           id: addr.id,
                                        //           houseNumber: addr.houseNumber,
                                        //           subDistrict: addr.subDistrict,
                                        //           district: addr.district,
                                        //           province: addr.province,
                                        //           zipCode: addr.postalCode,
                                        //           provinceId: null,
                                        //           lat: addr.latitude,
                                        //           lng: addr.longitude,
                                        //         );
                                        //   } else {
                                        //     await ref
                                        //         .read(userProvider.notifier)
                                        //         .saveTechnicianAddress(
                                        //           id: addr.id,
                                        //           houseNumber: addr.houseNumber,
                                        //           subDistrict: addr.subDistrict,
                                        //           district: addr.district,
                                        //           province: addr.province,
                                        //           zipCode: addr.postalCode,
                                        //           provinceId: null,
                                        //           lat: addr.latitude,
                                        //           lng: addr.longitude,
                                        //         );
                                        //   }
                                        // }
                                  Navigator.pop(context, addr.id); // ✅ pop ที่เดียว
                                  // if (mounted) {
                                  //   Navigator.pop(context, addr);
                                  // }
                                      }
                                    : null, // 👈 ถ้าเลือกไม่ได้ = กดไม่ได้

                                child: Opacity(
                                  opacity: isSelectable ? 1.0 : 0.4,
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      18,
                                      18,
                                      18,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          !isSelectable
                                              ? Icons.block
                                              : selectedAddressId == addr.id
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: isSelectable
                                              ? AppColors.primary
                                              : Colors.grey,
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "ที่อยู่ ${index + 1}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),

                                              const SizedBox(height: 6),

                                              Text(
                                                "${addr.combinedAddressInfo} "
                                                "${addr.subDistrict} ${addr.district} ${addr.province} ${addr.postalCode}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors
                                                      .colorTertiaryText,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              if (!isSelectable)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  child: Text(
                                                    "ที่อยู่นี้อยู่นอกพื้นที่ให้บริการ",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.redAccent,
                                                    ),
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
                              ),

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

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(color: Colors.white),
        child: SecondaryButton(
          text: "เพิ่มที่อยู่ใหม่",
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Address(
                  addressId: null,
                  houseNumber: '',
                  subDistrict: '',
                  district: '',
                  province: '',
                  postCode: 0,
                  provinceId: null,
                  districtId: null,
                  subDistrictId: null,
                  initialLat: null,
                  initialLng: null,
                  onSave: (data) async {
                    final user = ref.read(userProvider);
                    if (user == null) return;

                    final houseNumber = (data['house_number'] ?? '').toString();
                    final subDistrict = (data['sub_district'] ?? '').toString();
                    final district = (data['district'] ?? '').toString();
                    final province = (data['province'] ?? '').toString();
                    final zipCode = (data['postal_code'] ?? '').toString();

                    final provinceId = data['province_id'] as int?;
                    final districtId = data['district_id'] as int?;
                    final subDistrictId = data['sub_district_id'] as int?;

                    final lat = (data['lat'] as num?)?.toDouble();
                    final lng = (data['lng'] as num?)?.toDouble();

                    if (user.role == UserRole.customer) {
                      await ref
                          .read(userProvider.notifier)
                          .saveCustomerAddress(
                            id: null,
                            houseNumber: houseNumber,
                            subDistrict: subDistrict,
                            district: district,
                            province: province,
                            zipCode: zipCode,
                            provinceId: provinceId,
                            districtId: districtId,
                            subDistrictId: subDistrictId,
                            lat: lat,
                            lng: lng,
                          );
                    } else {
                      await ref
                          .read(userProvider.notifier)
                          .saveTechnicianAddress(
                            id: null,
                            houseNumber: houseNumber,
                            subDistrict: subDistrict,
                            district: district,
                            province: province,
                            zipCode: zipCode,
                            provinceId: provinceId,
                            districtId: districtId,
                            subDistrictId: subDistrictId,
                            lat: lat,
                            lng: lng,
                          );
                    }
                  },
                ),
              ),
            );
          },
          borderRadius: 10,
          padding: const EdgeInsets.symmetric(vertical: 6),
          icon: Icons.add_rounded,
        ),
      ),
    );
  }
}
