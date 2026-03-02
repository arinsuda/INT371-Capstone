import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/address_form_controller.dart';
import '../formatters/postcode_formatter.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/labeled_text_area.dart';
import '../widgets/master_data_search_field.dart';

class AddressFormFields extends ConsumerWidget {
  final TextEditingController labelCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressLineCtrl;
  final TextEditingController provinceCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController subDistrictCtrl;
  final TextEditingController postCodeCtrl;

  final FocusNode provinceFocusNode;
  final FocusNode districtFocusNode;
  final FocusNode subDistrictFocusNode;

  final VoidCallback onFieldChanged;
  final Function(LatLng)? onCoordinatesUpdate;
  final bool showLabelField;

  const AddressFormFields({
    super.key,
    required this.labelCtrl,
    required this.phoneCtrl,
    required this.addressLineCtrl,
    required this.provinceCtrl,
    required this.districtCtrl,
    required this.subDistrictCtrl,
    required this.postCodeCtrl,
    required this.provinceFocusNode,
    required this.districtFocusNode,
    required this.subDistrictFocusNode,
    required this.onFieldChanged,
    this.onCoordinatesUpdate,
    this.showLabelField = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(addressFormProvider);
    final formNotifier = ref.read(addressFormProvider.notifier);

    final provinceAsync = ref.watch(provincesProvider);
    final districtAsync = ref.watch(
      districtsProvider(formState.selectedProvinceId ?? 0),
    );
    final subDistrictAsync = ref.watch(
      subDistrictsProvider(formState.selectedDistrictId ?? 0),
    );

    return Column(
      children: [
        if (showLabelField) ...[
          LabeledTextField(
            label: "ชื่อ (เช่น บ้าน, ที่ทำงาน)",
            controller: labelCtrl,
          ),
          const SizedBox(height: 12),
        ],
        LabeledTextArea(
          label: "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
          controller: addressLineCtrl,
          validator: (v) => (v == null || v.isEmpty) ? "กรุณากรอกข้อมูล" : null,
        ),
        MasterDataSearchField<ProvinceModel>(
          label: "จังหวัด",
          controller: provinceCtrl,
          focusNode: provinceFocusNode,
          options: provinceAsync.value ?? [],
          isLoading: provinceAsync.isLoading,
          hasSelection: formState.selectedProvinceId != null,
          displayStringForOption: (item) => item.nameTh,
          onSelected: (item) async {
            provinceCtrl.text = item.nameTh;
            formNotifier.setProvinceId(item.id);

            districtCtrl.clear();
            subDistrictCtrl.clear();
            postCodeCtrl.clear();

            try {
              final point = await formNotifier.getSmartStartingPoint(
                subDistrict: '',
                district: '',
                province: item.nameTh,
              );
              formNotifier.setCoordinates(point);
              onCoordinatesUpdate?.call(point);
            } catch (e) {
              debugPrint('Error geocoding province: $e');
            }
            onFieldChanged();
          },
          onChanged: (val) => formNotifier.setProvinceId(null),
        ),
        MasterDataSearchField<DistrictModel>(
          label: "เขต/อำเภอ",
          controller: districtCtrl,
          focusNode: districtFocusNode,
          options: districtAsync.value ?? [],
          isLoading: districtAsync.isLoading,
          hasSelection: formState.selectedDistrictId != null,
          displayStringForOption: (item) => item.nameTh,
          onSelected: (item) async {
            districtCtrl.text = item.nameTh;
            formNotifier.setDistrictId(item.id);

            subDistrictCtrl.clear();
            postCodeCtrl.clear();

            try {
              final point = await formNotifier.getSmartStartingPoint(
                subDistrict: '',
                district: item.nameTh,
                province: provinceCtrl.text,
              );
              formNotifier.setCoordinates(point);
              onCoordinatesUpdate?.call(point);
            } catch (e) {
              debugPrint('Error geocoding district: $e');
            }
            onFieldChanged();
          },
          onChanged: (val) => formNotifier.setDistrictId(null),
        ),
        MasterDataSearchField<SubDistrictModel>(
          label: "แขวง/ตำบล",
          controller: subDistrictCtrl,
          focusNode: subDistrictFocusNode,
          options: subDistrictAsync.value ?? [],
          isLoading: subDistrictAsync.isLoading,
          hasSelection: formState.selectedSubDistrictId != null,
          displayStringForOption: (item) => item.nameTh,
          onSelected: (item) async {
            subDistrictCtrl.text = item.nameTh;
            formNotifier.setSubDistrictId(item.id, zipCode: item.postalCode);

            postCodeCtrl.text = item.postalCode;

            try {
              final point = await formNotifier.getSmartStartingPoint(
                subDistrict: item.nameTh,
                district: districtCtrl.text,
                province: provinceCtrl.text,
              );
              formNotifier.setCoordinates(point);
              onCoordinatesUpdate?.call(point);
            } catch (e) {
              debugPrint('Error geocoding sub-district: $e');
            }
            onFieldChanged();
          },
          onChanged: (val) => formNotifier.setSubDistrictId(null),
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: "รหัสไปรษณีย์",
          controller: postCodeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
            PostCodeFormatter(),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) return "กรุณากรอกรหัสไปรษณีย์";
            if (v.length != 5) return "รหัสไปรษณีย์ต้องมี 5 หลัก";
            return null;
          },
          onChanged: (val) => formNotifier.setZipCode(val),
        ),
        LabeledTextField(
          label: "เบอร์โทรสำหรับที่อยู่นี้ (ไม่บังคับ)",
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return null;
            if (value.length != 10) return "เบอร์โทรต้องมี 10 หลัก";
            return null;
          },
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
