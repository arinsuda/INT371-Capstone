import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/theme.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';

final currentLocationProvider = FutureProvider.autoDispose<LatLng?>((
  ref,
) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }

  final pos = await Geolocator.getCurrentPosition();
  return LatLng(pos.latitude, pos.longitude);
});

class _PostCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (text[0] == '0') return oldValue;
    return newValue;
  }
}

class Address extends ConsumerStatefulWidget {
  final String houseNumber;
  final String subDistrict;
  final String district;
  final String province;
  final int postCode;

  final Future<void> Function(Map<String, dynamic> data) onSave;

  const Address({
    super.key,
    required this.houseNumber,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postCode,
    required this.onSave,
  });

  @override
  ConsumerState<Address> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<Address> {
  late TextEditingController houseNumberController;
  late TextEditingController subDistrictController;
  late TextEditingController districtController;
  late TextEditingController provinceController;
  late TextEditingController postCodeController;

  final _formKey = GlobalKey<FormState>();

  int? _selectedProvinceId;

  bool hasChanged = false;
  bool allValid = false;
  bool _isLoading = false;

  final FocusNode _provinceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    houseNumberController = TextEditingController(text: widget.houseNumber);
    subDistrictController = TextEditingController(text: widget.subDistrict);
    districtController = TextEditingController(text: widget.district);
    provinceController = TextEditingController(text: widget.province);
    postCodeController = TextEditingController(
      text: widget.postCode == 0 ? '' : widget.postCode.toString(),
    );
  }

  @override
  void dispose() {
    houseNumberController.dispose();
    subDistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    postCodeController.dispose();
    _provinceFocusNode.dispose();
    super.dispose();
  }

  void _checkForm() {
    final changed =
        houseNumberController.text != widget.houseNumber ||
        subDistrictController.text != widget.subDistrict ||
        districtController.text != widget.district ||
        provinceController.text != widget.province ||
        postCodeController.text != widget.postCode.toString();

    bool valid = _formKey.currentState?.validate() ?? false;

    if (_selectedProvinceId == null) {
      valid = false;
    }

    if (changed != hasChanged || valid != allValid) {
      setState(() {
        hasChanged = changed;
        allValid = valid;
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate() && _selectedProvinceId != null) {
      setState(() => _isLoading = true);
      try {
        final updateData = {
          'house_number': houseNumberController.text,
          'sub_district': subDistrictController.text,
          'district': districtController.text,

          'province_id': _selectedProvinceId,

          'postal_code': postCodeController.text,
          'country': 'Thailand',
          'village': '',
          'moo': '',
          'soi': '',
          'road': '',
        };

        await widget.onSave(updateData);

        if (mounted) {
          ref.read(bottomSubPageProvider.notifier).state = null;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedProvinceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกจังหวัดจากรายการ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provinceAsync = ref.watch(provincesProvider);

    ref.listen<AsyncValue<List<ProvinceModel>>>(provincesProvider, (
      previous,
      next,
    ) {
      next.whenData((provinces) {
        if (_selectedProvinceId == null && widget.province.isNotEmpty) {
          try {
            final match = provinces.firstWhere(
              (p) => p.nameTh == widget.province,
            );
            setState(() {
              _selectedProvinceId = match.id;

              _checkForm();
            });
          } catch (_) {}
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            children: [
              Header(
                header: "ดูที่อยู่ของฉัน",
                onPressed: () =>
                    ref.read(bottomSubPageProvider.notifier).state = null,
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _buildTextArea(
                      "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
                      houseNumberController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "กรุณากรอกบ้านเลขที่";
                        }
                        if (v.length > 500) {
                          return "บ้านเลขที่ต้องไม่เกิน 500 ตัวอักษร";
                        }
                        return null;
                      },
                      onChanged: (_) => _checkForm(),
                    ),
                    _buildTextField(
                      "แขวง/ตำบล",
                      subDistrictController,
                      validator: (v) => (v == null || v.isEmpty)
                          ? "กรุณากรอกแขวง/ตำบล"
                          : null,
                      onChanged: (_) => _checkForm(),
                    ),
                    _buildTextField(
                      "เขต/อำเภอ",
                      districtController,
                      validator: (v) => (v == null || v.isEmpty)
                          ? "กรุณากรอกเขต/อำเภอ"
                          : null,
                      onChanged: (_) => _checkForm(),
                    ),
                    provinceAsync.when(
                      data: (provinces) => _buildProvinceSearchField(
                        "จังหวัด",
                        provinceController,
                        provinces,
                        isLoading: false,
                        focusNode: _provinceFocusNode,
                      ),
                      loading: () => _buildProvinceSearchField(
                        "จังหวัด",
                        provinceController,
                        [],
                        isLoading: true,
                        focusNode: _provinceFocusNode,
                      ),
                      error: (err, stack) => _buildTextField(
                        "จังหวัด (โหลดข้อมูลไม่สำเร็จ)",
                        provinceController,
                      ),
                    ),
                    _buildTextField(
                      "รหัสไปรษณีย์",
                      postCodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                        _PostCodeFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "กรุณากรอกรหัสไปรษณีย์";
                        }
                        if (!RegExp(r"^[1-9][0-9]{4}$").hasMatch(v)) {
                          return "รหัสไปรษณีย์ต้องเป็นตัวเลข 5 หลัก";
                        }
                        return null;
                      },
                      onChanged: (_) => _checkForm(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: hasChanged && allValid ? _onSave : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: AppColors.colorError,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            maxLength: 500,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'เขียนรายละเอียดเกี่ยวกับตัวคุณ...',
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceSearchField(
    String label,
    TextEditingController controller,
    List<ProvinceModel> provinces, {
    required bool isLoading,
    required FocusNode focusNode, // ✅ รับ Parameter เพิ่ม
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          RawAutocomplete<ProvinceModel>(
            textEditingController: controller,

            // ✅ ใช้ FocusNode ที่รับมา (ห้ามสร้างใหม่ตรงนี้เด็ดขาด)
            focusNode: focusNode,

            displayStringForOption: (option) => option.nameTh,

            // Logic การค้นหา
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (isLoading) return [];

              // ถ้าว่าง -> แสดงทั้งหมด
              if (textEditingValue.text.isEmpty) {
                return provinces;
              }

              // กรองข้อมูล
              final filtered = provinces.where((ProvinceModel option) {
                return option.nameTh.contains(textEditingValue.text);
              }).toList();

              // ถ้าไม่เจอ -> แสดง Dummy
              if (filtered.isEmpty) {
                return [
                  ProvinceModel(
                    id: -1,
                    nameTh: 'ไม่พบข้อมูล "${textEditingValue.text}"',
                  ),
                ];
              }

              return filtered;
            },

            // เมื่อเลือก
            onSelected: (ProvinceModel selection) {
              if (selection.id == -1) return;
              setState(() {
                _selectedProvinceId = selection.id;
                controller.text = selection.nameTh;
                _checkForm();
              });
              // ถ้าอยากให้เลือกแล้ว Keyboard หุบ ให้ uncomment บรรทัดล่าง
              // focusNode.unfocus();
            },

            // Input Field Builder
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode
                  fieldFocusNode, // RawAutocomplete จะส่ง node เดิมที่เราใส่เข้าไปกลับมาให้ใช้ตรงนี้
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: fieldFocusNode,
                    enabled: !isLoading,
                    onChanged: (val) {
                      // ถ้าลบหมด -> เคลียร์ ID
                      if (val.isEmpty) {
                        setState(() {
                          _selectedProvinceId = null;
                        });
                      }
                      // สำคัญ: สั่งให้ rebuild เพื่อ update สถานะปุ่ม
                      _checkForm();
                    },
                    // ✅ เพิ่ม onTap: แตะปุ๊บ ถ้าว่างอยู่ให้โชว์เลย (เผื่อมันปิดไป)
                    onTap: () {
                      if (textEditingController.text.isEmpty) {
                        // Trick: กำหนดค่าเดิมเข้าไปเพื่อกระตุ้นให้ List เด้งขึ้นมา
                        textEditingController.value =
                            textEditingController.value;
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return "กรุณาเลือกจังหวัด";
                      if (_selectedProvinceId == null && !isLoading)
                        return "กรุณาเลือกจากรายการ";
                      return null;
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      suffixIcon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                      hintText: isLoading ? "กำลังโหลด..." : "ค้นหาจังหวัด...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorStroke,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorStroke,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBorder,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorError,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorError,
                          width: 1.5,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: AppColors.colorError,
                        fontSize: 12,
                      ),
                    ),
                  );
                },

            // List View Builder (ส่วนแสดงผล)
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<ProvinceModel> onSelected,
                  Iterable<ProvinceModel> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200, // สูงสุด 200
                          maxWidth:
                              MediaQuery.of(context).size.width -
                              48, // กว้างเท่า Input
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap:
                              true, // ✅ หดความสูงเท่าข้อมูลจริง (1 บรรทัดก็สูงแค่ 1 บรรทัด)
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ProvinceModel option = options.elementAt(
                              index,
                            );
                            final isDummy = option.id == -1;

                            return InkWell(
                              onTap: isDummy ? null : () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Text(
                                  option.nameTh,
                                  style: TextStyle(
                                    color: isDummy ? Colors.grey : Colors.black,
                                    fontStyle: isDummy
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }
}
