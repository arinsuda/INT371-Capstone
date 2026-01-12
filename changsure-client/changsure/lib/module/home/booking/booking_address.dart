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

    return
      Address(
      houseNumber: currentAddress?.combinedAddressInfo ?? '',
      subDistrict: currentAddress?.subDistrict ?? '',
      district: currentAddress?.district ?? '',
      province: currentAddress?.province ?? '',
      postCode: int.tryParse(currentAddress?.postalCode ?? '0') ?? 0,

      onSave: (Map<String, dynamic> data) async {
        final String houseNumber = data['house_number'] ?? '';
        final String subDistrict = data['sub_district'] ?? '';
        final String district = data['district'] ?? '';
        final String province = data['province'] ?? '';
        final String zipCode = data['postal_code'] ?? '';

        bool success = false;
        final notifier = ref.read(userProvider.notifier);

        if (userState.role == UserRole.technician) {
          success = await notifier.saveTechnicianAddress(
            id: currentAddress?.id,
            houseNumber: houseNumber,
            subDistrict: subDistrict,
            district: district,
            province: province,
            zipCode: zipCode,
          );
        } else if (userState.role == UserRole.customer) {
          success = await notifier.saveCustomerAddress(
            id: currentAddress?.id,
            houseNumber: houseNumber,
            subDistrict: subDistrict,
            district: district,
            province: province,
            zipCode: zipCode,
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
      },
    );
  }
}
