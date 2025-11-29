import 'dart:convert';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../../state/bottom_bar_state.dart';
import '../theme.dart';

class _PostCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    if (text[0] == '0') {
      return oldValue;
    }

    return newValue;
  }
}

class Address extends StatefulWidget {
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
  State<Address> createState() => _AddressState();
}

class _AddressState extends State<Address> {
  LatLng? currentPosition;
  final mapController = MapController();

  // controllers
  late TextEditingController houseNumberController;
  late TextEditingController subDistrictController;
  late TextEditingController districtController;
  late TextEditingController provinceController;
  late TextEditingController postCodeController;

  // track if anything changed
  bool hasChanged = false;
  bool allValid = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    getLocation();

    // init controllers
    houseNumberController = TextEditingController(text: widget.houseNumber);
    subDistrictController = TextEditingController(text: widget.subDistrict);
    districtController = TextEditingController(text: widget.district);
    provinceController = TextEditingController(text: widget.province);
    postCodeController = TextEditingController(
      text: widget.postCode.toString(),
    );

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

  Future<void> getLocation() async {
    await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition();

    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  @override
  void dispose() {
    houseNumberController.dispose();
    subDistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    postCodeController.dispose();
    super.dispose();
  }

  // ---------- Widgets ----------
  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        String? Function(String?)? validator,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
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
            onChanged: (_) => _checkForm(),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            children: [
              Header(header: "ดูที่อยู่ของฉัน"),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
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
                    ),
                    _buildTextField(
                      "แขวง/ตำบล",
                      subDistrictController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกแขวง/ตำบล";
                        return null;
                      },
                    ),
                    _buildTextField(
                      "เขต/อำเภอ",
                      districtController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกเขต/อำเภอ";
                        return null;
                      },
                    ),
                    _buildTextField(
                      "จังหวัด",
                      provinceController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกจังหวัด";
                        return null;
                      },
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
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: hasChanged && allValid ? () {} : null,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}



Widget _buildTextArea(
  String label,
  TextEditingController controller, {
  String? Function(String?)? validator,
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
