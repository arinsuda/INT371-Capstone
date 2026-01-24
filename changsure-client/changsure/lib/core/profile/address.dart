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
  final int? addressId;
  final String? label;
  final String? phoneNumber;
  final String addressLine;
  final String subDistrict;
  final String district;
  final String province;

  final int postCode;
  final bool isPrimary;

  final int? provinceId;
  final int? districtId;
  final int? subDistrictId;

  final double? initialLat;
  final double? initialLng;

  final Future<bool> Function(Map<String, dynamic> data) onSave;
  final Future<void> Function(int id)? onDelete;

  const Address({
    super.key,
    this.addressId,
    this.label,
    this.phoneNumber,

    required this.addressLine,

    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postCode,
    this.isPrimary = false,

    this.provinceId,
    this.districtId,
    this.subDistrictId,

    this.initialLat,
    this.initialLng,

    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<Address> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<Address> {
  late TextEditingController labelCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressLineCtrl;
  late TextEditingController subDistrictCtrl;
  late TextEditingController districtCtrl;
  late TextEditingController provinceCtrl;
  late TextEditingController postCodeCtrl;

  bool _isPrimary = false;
  bool _phoneTouched = false;

  final _formKey = GlobalKey<FormState>();

  final FocusNode _provinceFocusNode = FocusNode();
  final FocusNode _districtFocusNode = FocusNode();
  final FocusNode _subDistrictFocusNode = FocusNode();

  final MapController _previewMapController = MapController();

  bool _hasInitialDataLoaded = false;
  bool _isDirty = false;

  LatLng _defaultCenter = const LatLng(13.7563, 100.5018);
  bool _isLoadingDefaultLocation = false;

  @override
  void initState() {
    super.initState();
    _isPrimary = widget.isPrimary;
    labelCtrl = TextEditingController(text: widget.label ?? '');

    phoneCtrl = TextEditingController(text: widget.phoneNumber ?? '');
    addressLineCtrl = TextEditingController(text: widget.addressLine);
    subDistrictCtrl = TextEditingController(text: widget.subDistrict);
    districtCtrl = TextEditingController(text: widget.district);
    provinceCtrl = TextEditingController(text: widget.province);
    postCodeCtrl = TextEditingController(
      text: widget.postCode == 0 ? '' : widget.postCode.toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoadingDefaultLocation = true);

      try {
        final controller = ref.read(addressFormProvider.notifier);
        final smartPoint = await controller.getSmartStartingPoint(
          subDistrict: widget.subDistrict,
          district: widget.district,
          province: widget.province,
        );

        if (mounted) {
          setState(() {
            _defaultCenter = smartPoint;
            _isLoadingDefaultLocation = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingDefaultLocation = false);
        }
      }

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

    final canSubmit =
        _formKey.currentState!.validate() &&
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('กรุณาระบุ$missingให้ครบถ้วน')));
      return;
    }

    ref.read(addressFormProvider.notifier).setLoading(true);

    try {
      final payload = <String, dynamic>{
        if (labelCtrl.text.trim().isNotEmpty) 'label': labelCtrl.text.trim(),
        'is_primary': _isPrimary,

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

      if (ok) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          ref.read(bottomSubPageProvider.notifier).state = const SubPageConfig(
            page: BottomSubPage.customerProfile,
          );
        }
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
      if (mounted) ref.read(addressFormProvider.notifier).setLoading(false);
    }
  }

  Future<void> _onDelete() async {
    if (widget.addressId == null || widget.onDelete == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบที่อยู่นี้ใช่หรือไม่?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.onDelete!(widget.addressId!);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบที่อยู่เรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
        }
      }
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

    final isEditing = widget.addressId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Header(
                header: "ที่อยู่ของฉัน",
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    ref
                        .read(bottomSubPageProvider.notifier)
                        .state = const SubPageConfig(
                      page: BottomSubPage.customerProfile,
                    );
                  }
                },
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
                      defaultCenter: _defaultCenter,
                      selectedCoordinates: formState.selectedCoordinates,
                      isMapLoading:
                          formState.isMapLoading || _isLoadingDefaultLocation,
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
                          LabeledTextField(
                            label: "ชื่อ (เช่น บ้าน, ที่ทำงาน)",
                            controller: labelCtrl,
                          ),
                          const SizedBox(height: 12),
                          LabeledTextArea(
                            label:
                                "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
                            controller: addressLineCtrl,
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
                            onSelected: (item) async {
                              provinceCtrl.text = item.nameTh;
                              formNotifier.setProvinceId(item.id);

                              districtCtrl.clear();
                              subDistrictCtrl.clear();
                              postCodeCtrl.clear();

                              try {
                                final point = await formNotifier
                                    .getSmartStartingPoint(
                                      subDistrict: '',
                                      district: '',
                                      province: item.nameTh,
                                    );
                                formNotifier.setCoordinates(point);
                                _previewMapController.move(point, 13.0);
                              } catch (e) {
                                print('Error geocoding province: $e');
                              }
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
                            onSelected: (item) async {
                              districtCtrl.text = item.nameTh;
                              formNotifier.setDistrictId(item.id);

                              subDistrictCtrl.clear();
                              postCodeCtrl.clear();

                              try {
                                final point = await formNotifier
                                    .getSmartStartingPoint(
                                      subDistrict: '',
                                      district: item.nameTh,
                                      province: provinceCtrl.text,
                                    );
                                formNotifier.setCoordinates(point);
                                _previewMapController.move(point, 14.0);
                              } catch (e) {
                                print('Error geocoding district: $e');
                              }
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
                            onSelected: (item) async {
                              subDistrictCtrl.text = item.nameTh;
                              formNotifier.setSubDistrictId(
                                item.id,
                                zipCode: item.postalCode,
                              );

                              postCodeCtrl.text = item.postalCode;

                              try {
                                final point = await formNotifier
                                    .getSmartStartingPoint(
                                      subDistrict: item.nameTh,
                                      district: districtCtrl.text,
                                      province: provinceCtrl.text,
                                    );
                                formNotifier.setCoordinates(point);
                                _previewMapController.move(point, 15.0);
                              } catch (e) {
                                print('Error geocoding sub-district: $e');
                              }
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
                              if (value.length != 10)
                                return "เบอร์โทรต้องมี 10 หลัก";
                              return null;
                            },
                            onChanged: (_) {
                              _phoneTouched = true;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            "ตั้งเป็นที่อยู่หลัก",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Checkbox(
                            value: _isPrimary,
                            activeColor: Colors.blue,
                            onChanged: (bool? value) {
                              setState(() {
                                _isPrimary = value ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: PrimaryButton(
                        text: "บันทึก",
                        onPressed: _isDirty ? _onSave : null,
                      ),
                    ),

                    if (isEditing && widget.onDelete != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: OutlinedButton(
                          onPressed: _onDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'ลบที่อยู่',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
