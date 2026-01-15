import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';

import 'controllers/address_form_controller.dart';
import 'formatters/postcode_formatter.dart';
import 'widgets/map_picker_sheet.dart';
import 'widgets/master_data_search_field.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/labeled_text_area.dart';
import 'widgets/map_preview.dart';

class Address extends ConsumerStatefulWidget {
  final String houseNumber;
  final String subDistrict;
  final String district;
  final String province;

  final int postCode;

  final int? provinceId;
  final int? districtId;
  final int? subDistrictId;

  final double? initialLat;
  final double? initialLng;

  final Future<void> Function(Map<String, dynamic> data) onSave;

  const Address({
    super.key,
    required this.houseNumber,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postCode,

    this.provinceId,
    this.districtId,
    this.subDistrictId,

    this.initialLat,
    this.initialLng,

    required this.onSave,
  });

  @override
  ConsumerState<Address> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<Address> {
  late TextEditingController houseNumberCtrl;
  late TextEditingController subDistrictCtrl;
  late TextEditingController districtCtrl;
  late TextEditingController provinceCtrl;
  late TextEditingController postCodeCtrl;

  final _formKey = GlobalKey<FormState>();

  final FocusNode _provinceFocusNode = FocusNode();
  final FocusNode _districtFocusNode = FocusNode();
  final FocusNode _subDistrictFocusNode = FocusNode();

  final MapController _previewMapController = MapController();

  bool _hasInitialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    houseNumberCtrl = TextEditingController(text: widget.houseNumber);
    subDistrictCtrl = TextEditingController(text: widget.subDistrict);
    districtCtrl = TextEditingController(text: widget.district);
    provinceCtrl = TextEditingController(text: widget.province);
    postCodeCtrl = TextEditingController(
      text: widget.postCode == 0 ? '' : widget.postCode.toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LatLng? initialCoords;
      if (widget.initialLat != null && widget.initialLng != null) {
        initialCoords = LatLng(widget.initialLat!, widget.initialLng!);
      }

      ref
          .read(addressFormProvider.notifier)
          .setInitialData(
            provinceId: widget.provinceId,
            districtId: widget.districtId,
            subDistrictId: widget.subDistrictId,
            zipCode: postCodeCtrl.text.isNotEmpty ? postCodeCtrl.text : null,
            coords: initialCoords,
          );

      if (initialCoords != null) {
        _previewMapController.move(initialCoords, 16.0);
      }
    });
  }

  @override
  void dispose() {
    houseNumberCtrl.dispose();
    subDistrictCtrl.dispose();
    districtCtrl.dispose();
    provinceCtrl.dispose();
    postCodeCtrl.dispose();
    _provinceFocusNode.dispose();
    _districtFocusNode.dispose();
    _subDistrictFocusNode.dispose();
    _previewMapController.dispose();
    super.dispose();
  }

  void _openMapPicker() async {
    final controller = ref.read(addressFormProvider.notifier);
    final startPoint = await controller.getSmartStartingPoint(
      subDistrict: subDistrictCtrl.text,
      district: districtCtrl.text,
      province: provinceCtrl.text,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapPickerSheet(
        initialCenter: startPoint,
        onPicked: (pickedLatLng) {
          controller.setCoordinates(pickedLatLng);
          _previewMapController.move(pickedLatLng, 16.0);
        },
      ),
    );
  }

  Future<void> _onSave() async {
    final formState = ref.read(addressFormProvider);

    if (_formKey.currentState!.validate() &&
        formState.selectedProvinceId != null &&
        formState.selectedDistrictId != null &&
        formState.selectedSubDistrictId != null) {
      ref.read(addressFormProvider.notifier).setLoading(true);
      try {
        final updateData = {
          'house_number': houseNumberCtrl.text,
          'sub_district': subDistrictCtrl.text,
          'district': districtCtrl.text,
          'province': provinceCtrl.text,
          'postal_code': postCodeCtrl.text,

          'province_id': formState.selectedProvinceId,
          'district_id': formState.selectedDistrictId,
          'sub_district_id': formState.selectedSubDistrictId,

          'country': 'Thailand',
          'lat': formState.selectedCoordinates?.latitude,
          'lng': formState.selectedCoordinates?.longitude,
        };

        await widget.onSave(updateData);

        if (mounted) {
          ref.read(bottomSubPageProvider.notifier).state = null;
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      } finally {
        if (mounted) ref.read(addressFormProvider.notifier).setLoading(false);
      }
    } else {
      String missing = '';
      if (formState.selectedProvinceId == null)
        missing = 'จังหวัด';
      else if (formState.selectedDistrictId == null)
        missing = 'เขต/อำเภอ';
      else if (formState.selectedSubDistrictId == null)
        missing = 'แขวง/ตำบล';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('กรุณาเลือก$missingจากรายการ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(addressFormProvider);
    final formNotifier = ref.read(addressFormProvider.notifier);

    final provinceAsync = ref.watch(provincesProvider);

    final districtAsync = ref.watch(
      districtsProvider(formState.selectedProvinceId ?? 0),
    );

    final subDistrictAsync = ref.watch(
      subDistrictsProvider(formState.selectedDistrictId ?? 0),
    );

    ref.listen<AsyncValue<List<ProvinceModel>>>(provincesProvider, (_, next) {
      next.whenData((provinces) {
        if (!_hasInitialDataLoaded &&
            widget.province.isNotEmpty &&
            formState.selectedProvinceId == null) {
          try {
            final match = provinces.firstWhere(
              (p) => p.nameTh == widget.province,
            );
            formNotifier.setProvinceId(match.id);
          } catch (_) {}
        }
      });
    });

    ref.listen<AsyncValue<List<DistrictModel>>>(
      districtsProvider(formState.selectedProvinceId ?? 0),
      (_, next) {
        next.whenData((districts) {
          if (widget.district.isNotEmpty &&
              formState.selectedDistrictId == null) {
            try {
              final match = districts.firstWhere(
                (d) => d.nameTh == widget.district,
              );
              formNotifier.setDistrictId(match.id);
            } catch (_) {}
          }
        });
      },
    );

    ref.listen<AsyncValue<List<SubDistrictModel>>>(
      subDistrictsProvider(formState.selectedDistrictId ?? 0),
      (_, next) {
        next.whenData((subs) {
          if (widget.subDistrict.isNotEmpty &&
              formState.selectedSubDistrictId == null) {
            try {
              final match = subs.firstWhere(
                (s) => s.nameTh == widget.subDistrict,
              );

              formNotifier.setSubDistrictId(
                match.id,
                zipCode: match.postalCode,
              );
              _hasInitialDataLoaded = true;
            } catch (_) {}
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Header(
                header: "ที่อยู่ของฉัน",
                onPressed: () =>
                    ref.read(bottomSubPageProvider.notifier).state = null,
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    MapPreview(
                      mapController: _previewMapController,
                      defaultCenter: const LatLng(13.7563, 100.5018),
                      selectedCoordinates: formState.selectedCoordinates,
                      isMapLoading: formState.isMapLoading,
                      onTapOpenPicker: _openMapPicker,
                      onTapCurrentLocation: () async {
                        try {
                          await ref
                              .read(addressFormProvider.notifier)
                              .useCurrentLocation();
                          final newCoord = ref
                              .read(addressFormProvider)
                              .selectedCoordinates;
                          if (newCoord != null)
                            _previewMapController.move(newCoord, 16.0);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          LabeledTextArea(
                            label:
                                "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
                            controller: houseNumberCtrl,
                            validator: (v) => (v == null || v.isEmpty)
                                ? "กรุณากรอกข้อมูล"
                                : null,
                          ),

                          MasterDataSearchField<ProvinceModel>(
                            label: "จังหวัด",
                            controller: provinceCtrl,
                            focusNode: _provinceFocusNode,
                            options: provinceAsync.value ?? [],
                            isLoading: provinceAsync.isLoading,
                            hasSelection: formState.selectedProvinceId != null,
                            displayStringForOption: (item) => item.nameTh,
                            onSelected: (item) {
                              provinceCtrl.text = item.nameTh;
                              formNotifier.setProvinceId(item.id);

                              districtCtrl.clear();
                              subDistrictCtrl.clear();
                              postCodeCtrl.clear();
                            },
                            onChanged: (val) =>
                                formNotifier.setProvinceId(null),
                          ),

                          MasterDataSearchField<DistrictModel>(
                            label: "เขต/อำเภอ",
                            controller: districtCtrl,
                            focusNode: _districtFocusNode,

                            options: districtAsync.value ?? [],
                            isLoading: districtAsync.isLoading,
                            hasSelection: formState.selectedDistrictId != null,
                            displayStringForOption: (item) => item.nameTh,
                            onSelected: (item) {
                              districtCtrl.text = item.nameTh;
                              formNotifier.setDistrictId(item.id);

                              subDistrictCtrl.clear();
                              postCodeCtrl.clear();
                            },
                            onChanged: (val) =>
                                formNotifier.setDistrictId(null),
                          ),

                          MasterDataSearchField<SubDistrictModel>(
                            label: "แขวง/ตำบล",
                            controller: subDistrictCtrl,
                            focusNode: _subDistrictFocusNode,
                            options: subDistrictAsync.value ?? [],
                            isLoading: subDistrictAsync.isLoading,
                            hasSelection:
                                formState.selectedSubDistrictId != null,
                            displayStringForOption: (item) => item.nameTh,
                            onSelected: (item) {
                              subDistrictCtrl.text = item.nameTh;
                              formNotifier.setSubDistrictId(
                                item.id,
                                zipCode: item.postalCode,
                              );

                              postCodeCtrl.text = item.postalCode;
                            },
                            onChanged: (val) =>
                                formNotifier.setSubDistrictId(null),
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
                              if (v == null || v.isEmpty)
                                return "กรุณากรอกรหัสไปรษณีย์";
                              if (v.length != 5)
                                return "รหัสไปรษณีย์ต้องมี 5 หลัก";
                              return null;
                            },

                            onChanged: (val) => formNotifier.setZipCode(val),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: PrimaryButton(text: "บันทึก", onPressed: _onSave),
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
