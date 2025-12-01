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
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Address(
          primaryAddress: state.primary,
          onSubmit: (payload) async {
            if (state.primary != null) {
              await state.updatePrimaryAddress(state.primary!.id, payload);
            } else {
              await state.createAddress(
                payload,
              );
            }
          },
        );
      },
    );
  }
}
