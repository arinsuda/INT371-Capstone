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

  String _formatThaiPhone(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10 && digits.startsWith('0')) {
      if (digits.startsWith('06') ||
          digits.startsWith('08') ||
          digits.startsWith('09')) {
        return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
      }
      if (digits.startsWith('02')) {
        return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return digits.isNotEmpty ? digits : raw.trim();
  }

  Future<void> _editAddress(AddressModel addr) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Address(
          addressId: addr.id,
          label: addr.label,
          phoneNumber: addr.phoneNumber,
          isPrimary: addr.isPrimary,

          addressLine: addr.addressLine,

          subDistrict: addr.subDistrict,
          district: addr.district,
          province: addr.province,
          postCode: int.tryParse(addr.postalCode) ?? 0,

          provinceId: addr.provinceId,
          districtId: addr.districtId,
          subDistrictId: addr.subDistrictId,

          initialLat: addr.latitude,
          initialLng: addr.longitude,

          onSave: (data) async {
            final userNow = ref.read(userProvider);
            if (userNow == null) return false;

            final String? label = (data['label'] as String?)?.trim();
            final dynamic rawPhone = data.containsKey('phone_number')
                ? data['phone_number']
                : null;

            final String? phoneNumber = rawPhone == null
                ? null
                : rawPhone.toString().trim();

            final bool isPrimary = data['is_primary'] as bool? ?? false;

            final String addressLine = (data['address_line'] ?? '')
                .toString()
                .trim();

            final int? provinceId = (data['province_id'] as num?)?.toInt();
            final int? districtId = (data['district_id'] as num?)?.toInt();
            final int? subDistrictId = (data['sub_district_id'] as num?)
                ?.toInt();

            final String zipCode = (data['postal_code'] ?? '')
                .toString()
                .trim();

            final double? lat = (data['latitude'] as num?)?.toDouble();
            final double? lng = (data['longitude'] as num?)?.toDouble();

            if (addressLine.isEmpty ||
                provinceId == null ||
                districtId == null ||
                subDistrictId == null ||
                lat == null ||
                lng == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกที่อยู่ให้ครบ')),
                );
              }
              return false;
            }

            final notifier = ref.read(userProvider.notifier);

            final bool success = (userNow.role == UserRole.customer)
                ? await notifier.saveCustomerAddress(
                    id: addr.id,
                    label: (label != null && label.isNotEmpty) ? label : null,
                    phoneNumber: phoneNumber,
                    isPrimary: isPrimary,

                    addressLine: addressLine,

                    zipCode: zipCode,
                    provinceId: provinceId,
                    districtId: districtId,
                    subDistrictId: subDistrictId,

                    lat: lat,
                    lng: lng,
                  )
                : await notifier.saveTechnicianAddress(
                    id: addr.id,
                    label: (label != null && label.isNotEmpty) ? label : null,
                    phoneNumber: phoneNumber,
                    isPrimary: isPrimary,

                    addressLine: addressLine,
                    zipCode: zipCode,
                    provinceId: provinceId,
                    districtId: districtId,
                    subDistrictId: subDistrictId,

                    lat: lat,
                    lng: lng,
                  );

            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('บันทึกข้อมูลล้มเหลว กรุณาลองใหม่'),
                ),
              );
            }

            return success;
          },

          onDelete: (id) async {
            final userNow = ref.read(userProvider);
            if (userNow == null) return;

            if (userNow.role == UserRole.customer) {
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
    final displayAddresses = [...raw];

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
                  Navigator.pop(context, selectedAddressId);
                },
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.primaryBGHover,
                child: addresses == null
                    ? const Center(child: CircularProgressIndicator())
                    : displayAddresses.isEmpty
                    ? const Center(child: Text("ยังไม่มีที่อยู่"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        itemCount: displayAddresses.length,
                        itemBuilder: (context, index) {
                          final addr = displayAddresses[index];
                          final isLast = index == displayAddresses.length - 1;

                          final bool isSelectable =
                              widget.provinceId == null ||
                              addr.provinceId == widget.provinceId;

                          String displayName = "ที่อยู่ ${index + 1}";
                          if (addr.label != null && addr.label!.isNotEmpty) {
                            displayName = addr.label!;
                          }

                          final formattedPhone = _formatThaiPhone(
                            addr.phoneNumber,
                          );

                          final displayTitle = formattedPhone.isNotEmpty
                              ? '$displayName $formattedPhone'
                              : displayName;

                          return Column(
                            children: [
                              InkWell(
                                onTap: isSelectable
                                    ? () {
                                        Navigator.pop(context, addr.id);
                                      }
                                    : null,
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
                                              RichText(
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: displayName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    if (formattedPhone
                                                        .isNotEmpty)
                                                      TextSpan(
                                                        text:
                                                            '  $formattedPhone',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontSize: 14,
                                                          color: AppColors
                                                              .colorTertiaryText,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 6),
                                              Text(
                                                "${addr.addressLine} "
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
                                        IconButton(
                                          icon: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => _editAddress(addr),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
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
                                  color: AppColors.colorStroke,
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
                  label: '',
                  phoneNumber: '',
                  isPrimary: false,

                  addressLine: '',

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
                    final userNow = ref.read(userProvider);
                    if (userNow == null) return false;

                    final String? label = (data['label'] as String?)?.trim();
                    final dynamic rawPhone = data.containsKey('phone_number')
                        ? data['phone_number']
                        : null;

                    final String? phoneNumber = rawPhone == null
                        ? null
                        : rawPhone.toString().trim();

                    final bool isPrimary = data['is_primary'] as bool? ?? false;

                    final String addressLine = (data['address_line'] ?? '')
                        .toString()
                        .trim();
                    final String zipCode = (data['postal_code'] ?? '')
                        .toString()
                        .trim();

                    final int? provinceId = (data['province_id'] as num?)
                        ?.toInt();
                    final int? districtId = (data['district_id'] as num?)
                        ?.toInt();
                    final int? subDistrictId = (data['sub_district_id'] as num?)
                        ?.toInt();

                    final double? lat = (data['latitude'] as num?)?.toDouble();
                    final double? lng = (data['longitude'] as num?)?.toDouble();

                    if (addressLine.isEmpty ||
                        zipCode.isEmpty ||
                        provinceId == null ||
                        districtId == null ||
                        subDistrictId == null ||
                        lat == null ||
                        lng == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'กรุณากรอกที่อยู่ให้ครบ และเลือกตำแหน่งบนแผนที่',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return false;
                    }

                    final notifier = ref.read(userProvider.notifier);

                    final bool success = (userNow.role == UserRole.customer)
                        ? await notifier.saveCustomerAddress(
                            id: null,
                            label: (label != null && label.isNotEmpty)
                                ? label
                                : null,
                            phoneNumber: phoneNumber,
                            isPrimary: isPrimary,

                            addressLine: addressLine,

                            zipCode: zipCode,
                            provinceId: provinceId,
                            districtId: districtId,
                            subDistrictId: subDistrictId,

                            lat: lat,
                            lng: lng,
                          )
                        : await notifier.saveTechnicianAddress(
                            id: null,
                            label: (label != null && label.isNotEmpty)
                                ? label
                                : null,
                            phoneNumber: phoneNumber,
                            isPrimary: isPrimary,

                            addressLine: addressLine,

                            zipCode: zipCode,
                            provinceId: provinceId,
                            districtId: districtId,
                            subDistrictId: subDistrictId,

                            lat: lat,
                            lng: lng,
                          );

                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('บันทึกข้อมูลล้มเหลว กรุณาลองใหม่'),
                        ),
                      );
                    }

                    return success;
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
