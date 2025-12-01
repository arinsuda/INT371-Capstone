import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:changsure/core/profile/address.dart';
import 'package:changsure/state/customer_address_state.dart';

class CustomerAddressPage extends StatelessWidget {
  const CustomerAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerAddressState>(
      builder: (context, state, _) {
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Address(
          primaryAddress: state.primary,

          // 👇 ค่า default สำหรับ UI แบบ old
          defaultHouseNumber: "126 บ้านธรรมรักษา ถนนประชาอุทิศ",
          defaultSubDistrict: "บางมด",
          defaultDistrict: "ทุ่งครุ",
          defaultProvince: "กรุงเทพมหานคร",
          defaultPostCode: "10140",

          // 👇 logic แบบ new
          onSubmit: (payload) async {
            await state.savePrimaryAddress(payload);
          },
        );
      },
    );
  }
}
