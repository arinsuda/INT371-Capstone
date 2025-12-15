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

  const Address({
    super.key,
    required this.houseNumber,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postCode,
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

  final mapController = MapController();
  final _formKey = GlobalKey<FormState>();

  bool hasChanged = false;
  bool allValid = false;

  @override
  void initState() {
    super.initState();

    houseNumberController = TextEditingController(text: widget.houseNumber);
    subDistrictController = TextEditingController(text: widget.subDistrict);
    districtController = TextEditingController(text: widget.district);
    provinceController = TextEditingController(text: widget.province);
    postCodeController = TextEditingController(
      text: widget.postCode.toString(),
    );
  }

  @override
  void dispose() {
    houseNumberController.dispose();
    subDistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    postCodeController.dispose();
    mapController.dispose();
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

    if (changed != hasChanged || valid != allValid) {
      setState(() {
        hasChanged = changed;
        allValid = valid;
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      /*
       final updateData = {
         'houseNumber': houseNumberController.text,
         'subDistrict': subDistrictController.text,
         
       };
       
       */

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Header(
                header: "ดูที่อยู่ของฉัน",
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  children: [
                    const SizedBox(height: 16),

                    /*
                    locationAsync.when(
                      data: (pos) => pos != null 
                        ? Text("พิกัด: ${pos.latitude}, ${pos.longitude}") 
                        : const SizedBox(),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => const SizedBox(),
                    ),
                    */
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          _buildTextArea(
                            "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
                            houseNumberController,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return "กรุณากรอกบ้านเลขที่";
                              if (v.length > 500)
                                return "บ้านเลขที่ต้องไม่เกิน 500 ตัวอักษร";
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
                          _buildTextField(
                            "จังหวัด",
                            provinceController,
                            validator: (v) => (v == null || v.isEmpty)
                                ? "กรุณากรอกจังหวัด"
                                : null,
                            onChanged: (_) => _checkForm(),
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
                              if (v == null || v.isEmpty)
                                return "กรุณากรอกรหัสไปรษณีย์";
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
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
}
