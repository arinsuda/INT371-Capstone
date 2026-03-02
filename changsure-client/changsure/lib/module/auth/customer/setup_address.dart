import 'package:changsure/module/auth/start_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/header.dart';
import '../../../core/profile/controllers/address_form_controller.dart';
import '../../../core/profile/widgets/address_form_fields.dart';
import '../../../state/bottom_nav_provider.dart';

class SetupAddress extends ConsumerStatefulWidget {
  final String? label;
  final String? phoneNumber;
  final String? addressLine;
  final String? subDistrict;
  final String? district;
  final String? province;
  final int? postCode;

  final int? provinceId;
  final int? districtId;
  final int? subDistrictId;

  final double? initialLat;
  final double? initialLng;

  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const SetupAddress({
    super.key,
    this.label,
    this.phoneNumber,
    this.addressLine,
    this.subDistrict,
    this.district,
    this.province,
    this.postCode,
    this.provinceId,
    this.districtId,
    this.subDistrictId,
    this.initialLat,
    this.initialLng,
    required this.onSave,
  });

  @override
  ConsumerState<SetupAddress> createState() => _SetupAddressState();
}

class _SetupAddressState extends ConsumerState<SetupAddress> {
  late TextEditingController labelCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressLineCtrl;
  late TextEditingController subDistrictCtrl;
  late TextEditingController districtCtrl;
  late TextEditingController provinceCtrl;
  late TextEditingController postCodeCtrl;

  final _formKey = GlobalKey<FormState>();

  final FocusNode _provinceFocusNode = FocusNode();
  final FocusNode _districtFocusNode = FocusNode();
  final FocusNode _subDistrictFocusNode = FocusNode();
  bool _isDirty = false;
  bool _phoneTouched = false;

  @override
  void initState() {
    super.initState();

    labelCtrl = TextEditingController(text: widget.label ?? '');
    phoneCtrl = TextEditingController(text: widget.phoneNumber ?? '');
    addressLineCtrl = TextEditingController(text: widget.addressLine ?? '');
    subDistrictCtrl = TextEditingController(text: widget.subDistrict ?? '');
    districtCtrl = TextEditingController(text: widget.district ?? '');
    provinceCtrl = TextEditingController(text: widget.province ?? '');
    postCodeCtrl = TextEditingController(
      text: widget.postCode == null || widget.postCode == 0
          ? ''
          : widget.postCode.toString(),
    );

    phoneCtrl.addListener(() {
      _phoneTouched = true;
      _markDirty();
    });

    labelCtrl.addListener(_markDirty);
    addressLineCtrl.addListener(_markDirty);
    postCodeCtrl.addListener(_markDirty);

    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final controller = ref.read(addressFormProvider.notifier);
      } catch (e) {
        if (mounted) {}
      }

      ref
          .read(addressFormProvider.notifier)
          .setInitialData(
            provinceId: widget.provinceId,
            districtId: widget.districtId,
            subDistrictId: widget.subDistrictId,
            zipCode: postCodeCtrl.text.isNotEmpty ? postCodeCtrl.text : null,
          );
    });
  }

  @override
  void dispose() {
    labelCtrl.dispose();
    phoneCtrl.dispose();
    addressLineCtrl.dispose();
    subDistrictCtrl.dispose();
    districtCtrl.dispose();
    provinceCtrl.dispose();
    postCodeCtrl.dispose();
    _provinceFocusNode.dispose();
    _districtFocusNode.dispose();
    _subDistrictFocusNode.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _onSave() async {
    final formState = ref.read(addressFormProvider);

    final isValidForm = _formKey.currentState?.validate() ?? false;

    final canSubmit =
        isValidForm &&
        formState.selectedProvinceId != null &&
        formState.selectedDistrictId != null &&
        formState.selectedSubDistrictId != null &&
        addressLineCtrl.text.trim().isNotEmpty &&
        formState.selectedCoordinates != null;

    if (!canSubmit) {
      String missing = '';

      if (addressLineCtrl.text.trim().isEmpty) {
        missing = 'บ้านเลขที่';
      } else if (formState.selectedProvinceId == null) {
        missing = 'จังหวัด';
      } else if (formState.selectedDistrictId == null) {
        missing = 'เขต/อำเภอ';
      } else if (formState.selectedSubDistrictId == null) {
        missing = 'แขวง/ตำบล';
      } else if (formState.selectedCoordinates == null) {
        missing = 'พิกัดแผนที่';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('กรุณาระบุ$missingให้ครบถ้วน')));
      }
      return;
    }

    ref.read(addressFormProvider.notifier).setLoading(true);

    try {
      final payload = <String, dynamic>{
        if (labelCtrl.text.trim().isNotEmpty) 'label': labelCtrl.text.trim(),
        if (_phoneTouched)
          'phone_number': phoneCtrl.text.trim().isEmpty
              ? null
              : phoneCtrl.text.trim(),
        'address_line': addressLineCtrl.text.trim(),
        'province_id': formState.selectedProvinceId,
        'district_id': formState.selectedDistrictId,
        'sub_district_id': formState.selectedSubDistrictId,
        'latitude': formState.selectedCoordinates!.latitude,
        'longitude': formState.selectedCoordinates!.longitude,
        if (postCodeCtrl.text.trim().isNotEmpty)
          'postal_code': postCodeCtrl.text.trim(),
      };

      final ok = await widget.onSave(payload);

      if (!mounted) return;
      print("SAVE RESULT = $ok");

      if (ok == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StartPage()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลล้มเหลว กรุณาลองใหม่')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        ref.read(addressFormProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(addressFormProvider).isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Header(
                header: "ตั้งค่าโปรไฟล์",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AddressFormFields(
                        labelCtrl: labelCtrl,
                        phoneCtrl: phoneCtrl,
                        addressLineCtrl: addressLineCtrl,
                        provinceCtrl: provinceCtrl,
                        districtCtrl: districtCtrl,
                        subDistrictCtrl: subDistrictCtrl,
                        postCodeCtrl: postCodeCtrl,
                        provinceFocusNode: _provinceFocusNode,
                        districtFocusNode: _districtFocusNode,
                        subDistrictFocusNode: _subDistrictFocusNode,
                        onFieldChanged: _markDirty,
                        showLabelField: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: PrimaryButton(
                        text: "บันทึก",
                        onPressed: (!_isDirty || isLoading) ? null : _onSave,
                        padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
