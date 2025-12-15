import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/profile/address.dart';

class AddressPage extends ConsumerWidget {
  const AddressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Address(
      houseNumber: '126 บ้านธรรมรักษา ถนนประชาอุทิศ',
      subDistrict: 'บางมด',
      district: 'ทุ่งครุ',
      province: 'กรุงเทพมหานคร',
      postCode: 10140,
    );
  }
}
