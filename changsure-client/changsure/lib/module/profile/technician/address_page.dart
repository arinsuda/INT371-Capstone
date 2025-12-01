import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:changsure/state/technician_address_state.dart';
import 'package:changsure/core/profile/address.dart';

class AddressPage extends StatelessWidget {
  const AddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicianAddressState>(
      builder: (context, state, _) {
        // Loading state
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ถ้าระบบยังไม่มี primary address → ใช้ค่า default แบบ old version
        final defaultAddress = {
          "houseNumber": "126 บ้านธรรมรักษา ถนนประชาอุทิศ",
          "subDistrict": "บางมด",
          "district": "ทุ่งครุ",
          "province": "กรุงเทพมหานคร",
          "postCode": "10140",
        };

        return Address(
          // ถ้ามี primary address → ส่งเข้า Address()
          // ถ้ายังไม่มี → ส่ง null ให้ Address handle + default UI
          primaryAddress: state.primary,

          // ส่ง default สำหรับ UI (old behavior)
          defaultHouseNumber: defaultAddress["houseNumber"],
          defaultSubDistrict: defaultAddress["subDistrict"],
          defaultDistrict: defaultAddress["district"],
          defaultProvince: defaultAddress["province"],
          defaultPostCode: defaultAddress["postCode"],

          // 👇 logic ใหม่ที่ใช้ provider state
          onSubmit: (payload) async {
            if (state.primary != null) {
              await state.updatePrimaryAddress(state.primary!.id, payload);
            } else {
              await state.createAddress(payload);
            }
          },
        );
      },
    );
  }
}
