import 'package:flutter/material.dart';

import '../../../core/profile/address.dart';

class BookingAddress extends StatelessWidget {
  const BookingAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return const Address(
      houseNumber: '126 บ้านธรรมรักษา ถนนประชาอุทิศ',
      subDistrict: 'บางมด',
      district: 'ทุ่งครุ',
      province: 'กรุงเทพมหานคร',
      postCode: 10140,
    );
  }
}
