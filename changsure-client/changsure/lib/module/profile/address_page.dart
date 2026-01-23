import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/profile/address.dart';
import 'package:changsure/data/models/address_model.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/state/user_provider.dart';

class AddressPage extends ConsumerWidget {
  const AddressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    if (userState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    AddressModel? currentAddress;

    if (userState.role == UserRole.technician) {
      final list = userState.technicianProfile?.addresses ?? [];
      if (list.isNotEmpty) currentAddress = list.first;
    } else {
      final list = userState.addresses ?? [];
      if (list.isNotEmpty) {
        currentAddress = list.firstWhere(
          (e) => e.isPrimary == true,
          orElse: () => list.first,
        );
      }
    }

    return Address(
      addressId: currentAddress?.id,
      label: currentAddress?.label ?? '',
      isPrimary: currentAddress?.isPrimary ?? false,

      houseNumber: currentAddress?.houseNumber ?? '',
      village: currentAddress?.village,
      moo: currentAddress?.moo,
      soi: currentAddress?.soi,
      road: currentAddress?.road,

      subDistrict: currentAddress?.subDistrict ?? '',
      district: currentAddress?.district ?? '',
      province: currentAddress?.province ?? '',
      postCode: int.tryParse(currentAddress?.postalCode ?? '0') ?? 0,

      provinceId: currentAddress?.provinceId,
      districtId: currentAddress?.districtId,
      subDistrictId: currentAddress?.subDistrictId,

      initialLat: currentAddress?.latitude,
      initialLng: currentAddress?.longitude,

      onSave: (Map<String, dynamic> data) async {
        final notifier = ref.read(userProvider.notifier);

        final String label = (data['label'] ?? '').toString().trim();
        final dynamic rawPhone = data.containsKey('phone_number')
            ? data['phone_number']
            : null;

        final String? phoneNumber = rawPhone == null
            ? null
            : rawPhone.toString().trim();

        final bool isPrimary = data['is_primary'] as bool? ?? false;

        final String houseNumber = (data['house_number'] ?? '')
            .toString()
            .trim();

        final String? village = (data['village'] as String?)?.trim();
        final String? moo = (data['moo'] as String?)?.trim();
        final String? soi = (data['soi'] as String?)?.trim();
        final String? road = (data['road'] as String?)?.trim();

        final String zipCode = (data['postal_code'] ?? '').toString().trim();

        final int? provinceIdN = (data['province_id'] as num?)?.toInt();
        final int? districtIdN = (data['district_id'] as num?)?.toInt();
        final int? subDistrictIdN = (data['sub_district_id'] as num?)?.toInt();

        final double? latN = (data['latitude'] as num?)?.toDouble();
        final double? lngN = (data['longitude'] as num?)?.toDouble();

        final missing = <String>[];
        if (houseNumber.isEmpty) missing.add('บ้านเลขที่');
        if (zipCode.isEmpty) missing.add('รหัสไปรษณีย์');
        if (provinceIdN == null) missing.add('จังหวัด');
        if (districtIdN == null) missing.add('เขต/อำเภอ');
        if (subDistrictIdN == null) missing.add('แขวง/ตำบล');
        if (latN == null || lngN == null) missing.add('พิกัดแผนที่');

        if (missing.isNotEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('กรุณากรอกให้ครบ: ${missing.join(', ')}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }

        final int provinceId = provinceIdN!;
        final int districtId = districtIdN!;
        final int subDistrictId = subDistrictIdN!;
        final double lat = latN!;
        final double lng = lngN!;

        bool success = false;

        if (userState.role == UserRole.technician) {
          final int? addressId =
              (currentAddress?.id != null && (currentAddress!.id) > 0)
              ? currentAddress!.id
              : null;

          success = await notifier.saveTechnicianAddress(
            id: addressId,
            label: label.isNotEmpty ? label : null,
            phoneNumber: phoneNumber,
            isPrimary: isPrimary,

            houseNumber: houseNumber,
            village: (village != null && village.isNotEmpty) ? village : null,
            moo: (moo != null && moo.isNotEmpty) ? moo : null,
            soi: (soi != null && soi.isNotEmpty) ? soi : null,
            road: (road != null && road.isNotEmpty) ? road : null,

            zipCode: zipCode,

            provinceId: provinceId,
            districtId: districtId,
            subDistrictId: subDistrictId,

            lat: lat,
            lng: lng,
          );
        } else {
          success = await notifier.saveCustomerAddress(
            id: currentAddress?.id,
            phoneNumber: phoneNumber,
            label: label.isNotEmpty ? label : null,
            isPrimary: isPrimary,

            houseNumber: houseNumber,
            village: (village != null && village.isNotEmpty) ? village : null,
            moo: (moo != null && moo.isNotEmpty) ? moo : null,
            soi: (soi != null && soi.isNotEmpty) ? soi : null,
            road: (road != null && road.isNotEmpty) ? road : null,

            zipCode: zipCode,

            provinceId: provinceId,
            districtId: districtId,
            subDistrictId: subDistrictId,

            lat: lat,
            lng: lng,
          );
        }

        if (!success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('บันทึกข้อมูลล้มเหลว กรุณาลองใหม่')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
          }
        }
        return success;
      },
    );
  }
}
