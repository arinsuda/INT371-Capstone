// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../core/profile/address.dart';
// import 'package:changsure/data/models/address_model.dart';
// import 'package:changsure/state/user_provider.dart';

// class AddressPage extends ConsumerWidget {
//   const AddressPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userState = ref.watch(userProvider);

//     if (userState == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     final List<AddressModel> addresses =
//         userState.technicianProfile?.addresses ?? [];

//     final AddressModel? currentAddress = addresses.isNotEmpty
//         ? (addresses.firstWhere(
//             (element) => element.isPrimary,
//             orElse: () => addresses.first,
//           ))
//         : null;

//     return Address(
//       houseNumber: currentAddress?.combinedAddressInfo ?? '',
//       subDistrict: currentAddress?.subDistrict ?? '',
//       district: currentAddress?.district ?? '',
//       province: currentAddress?.province ?? '',
//       postCode: int.tryParse(currentAddress?.postalCode ?? '0') ?? 0,

//       onSave: (Map<String, dynamic> data) async {
//         final String houseNumber = data['house_number'] ?? '';
//         final String subDistrict = data['sub_district'] ?? '';
//         final String district = data['district'] ?? '';
//         final String province = data['province'] ?? '';
//         final String zipCode = data['postal_code'] ?? '';

//         final success = await ref
//             .read(userProvider.notifier)
//             .saveAddress(
//               id: currentAddress?.id,
//               houseNumber: houseNumber,
//               subDistrict: subDistrict,
//               district: district,
//               province: province,
//               zipCode: zipCode,
//             );

//         if (!success) {
//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('บันทึกข้อมูลล้มเหลว กรุณาลองใหม่')),
//             );
//           }
//         }
//       },
//     );
//   }
// }
