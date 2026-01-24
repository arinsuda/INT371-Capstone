import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/profile/address.dart';
import 'package:changsure/data/models/address_model.dart';
import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/state/user_provider.dart';

class BookingAddress extends ConsumerWidget {
  const BookingAddress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    if (userState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<AddressModel> addresses = [];
    if (userState.role == UserRole.technician) {
      addresses = userState.technicianProfile?.addresses ?? [];
    } else {
      addresses = userState.addresses ?? [];
    }

    final AddressModel? currentAddress = addresses.isNotEmpty
        ? (addresses.firstWhere(
            (element) => element.isPrimary,
            orElse: () => addresses.first,
          ))
        : null;

    return Address(
      addressId: currentAddress?.id,
      label: currentAddress?.label ?? '',
      isPrimary: currentAddress?.isPrimary ?? false,

      addressLine: currentAddress?.addressLine ?? '',

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

        final String label = (data['label'] ?? currentAddress?.label ?? '')
            .toString();
        final bool isPrimary =
            (data['is_primary'] as bool?) ??
            (currentAddress?.isPrimary ?? false);

        final String addressLine =
            (data['address_line'] ?? currentAddress?.addressLine ?? '')
                .toString();

        final String subDistrict =
            (data['sub_district'] ?? currentAddress?.subDistrict ?? '')
                .toString();
        final String district =
            (data['district'] ?? currentAddress?.district ?? '').toString();
        final String province =
            (data['province'] ?? currentAddress?.province ?? '').toString();

        final String zipCode =
            (data['postal_code'] ?? currentAddress?.postalCode ?? '')
                .toString();

        final int? provinceId =
            (data['province_id'] as int?) ?? currentAddress?.provinceId;
        final int? districtId =
            (data['district_id'] as int?) ?? currentAddress?.districtId;
        final int? subDistrictId =
            (data['sub_district_id'] as int?) ?? currentAddress?.subDistrictId;

        final double? lat =
            ((data['lat'] as num?)?.toDouble()) ??
            ((data['latitude'] as num?)?.toDouble()) ??
            currentAddress?.latitude;

        final double? lng =
            ((data['lng'] as num?)?.toDouble()) ??
            ((data['longitude'] as num?)?.toDouble()) ??
            currentAddress?.longitude;

        if (addressLine.trim().isEmpty ||
            subDistrict.trim().isEmpty ||
            district.trim().isEmpty ||
            province.trim().isEmpty ||
            zipCode.trim().isEmpty ||
            provinceId == null ||
            districtId == null ||
            subDistrictId == null ||
            lat == null ||
            lng == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ข้อมูลที่อยู่ไม่ครบ (ต้องมีจังหวัด/อำเภอ/ตำบล + พิกัด)',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }

        bool success = false;

        if (userState.role == UserRole.technician) {
          success = await notifier.saveTechnicianAddress(
            id: currentAddress?.id,
            label: label,
            isPrimary: isPrimary,

            addressLine: addressLine,
            zipCode: zipCode,

            provinceId: provinceId,
            districtId: districtId,
            subDistrictId: subDistrictId,

            lat: lat,
            lng: lng,
          );
        } else if (userState.role == UserRole.customer) {
          success = await notifier.saveCustomerAddress(
            id: currentAddress?.id,
            label: label,
            isPrimary: isPrimary,

            addressLine: addressLine,
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
              const SnackBar(
                content: Text('บันทึกข้อมูลไม่สำเร็จ โปรดลองอีกครั้ง'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('บันทึกที่อยู่สำเร็จ')),
            );
          }
        }
        return success;
      },
    );
  }
}
