import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/address/address_model.dart';
import '../theme.dart';
import '../button/primary_button.dart';
import '../header.dart';

class Address extends StatefulWidget {
  final AddressModel? primaryAddress;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const Address({
    super.key,
    required this.primaryAddress,
    required this.onSubmit,
  });

  @override
  State<Address> createState() => _AddressState();
}

class _AddressState extends State<Address> {
  LatLng? _currentPosition;
  bool _hasChanged = false;
  bool _isLoading = false;

  late final TextEditingController _houseNumberController;
  late final TextEditingController _subDistrictController;
  late final TextEditingController _districtController;
  late final TextEditingController _provinceController;
  late final TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _populateFields(widget.primaryAddress);
    _requestLocationPermission();
  }

  @override
  void didUpdateWidget(Address oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ถ้า wrapper ส่งข้อมูลใหม่เข้ามา เช่นโหลดเสร็จ
    if (oldWidget.primaryAddress != widget.primaryAddress) {
      _populateFields(widget.primaryAddress);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _houseNumberController = TextEditingController();
    _subDistrictController = TextEditingController();
    _districtController = TextEditingController();
    _provinceController = TextEditingController();
    _postalCodeController = TextEditingController();

    _houseNumberController.addListener(_onFieldChanged);
    _subDistrictController.addListener(_onFieldChanged);
    _districtController.addListener(_onFieldChanged);
    _provinceController.addListener(_onFieldChanged);
    _postalCodeController.addListener(_onFieldChanged);
  }

  void _disposeControllers() {
    _houseNumberController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
  }

  void _populateFields(AddressModel? address) {
    if (address == null) return;

    _houseNumberController.text = address.houseNumber ?? "";
    _subDistrictController.text = address.subDistrict ?? "";
    _districtController.text = address.district ?? "";
    _provinceController.text = address.province ?? "";
    _postalCodeController.text = address.postalCode ?? "";

    if (address.latitude != null && address.longitude != null) {
      _currentPosition = LatLng(address.latitude!, address.longitude!);
    }

    setState(() => _hasChanged = false);
  }

  void _onFieldChanged() {
    final a = widget.primaryAddress;

    final changed =
        _houseNumberController.text != (a?.houseNumber ?? "") ||
        _subDistrictController.text != (a?.subDistrict ?? "") ||
        _districtController.text != (a?.district ?? "") ||
        _provinceController.text != (a?.province ?? "") ||
        _postalCodeController.text != (a?.postalCode ?? "");

    if (changed != _hasChanged) {
      setState(() => _hasChanged = changed);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      final pos = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  bool _validate() {
    if (_houseNumberController.text.isEmpty) {
      _error("กรุณากรอกบ้านเลขที่");
      return false;
    }
    if (_subDistrictController.text.isEmpty) {
      _error("กรุณากรอกแขวง/ตำบล");
      return false;
    }
    if (_districtController.text.isEmpty) {
      _error("กรุณากรอกเขต/อำเภอ");
      return false;
    }
    if (_provinceController.text.isEmpty) {
      _error("กรุณากรอกจังหวัด");
      return false;
    }
    if (_postalCodeController.text.isEmpty) {
      _error("กรุณากรอกรหัสไปรษณีย์");
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      "house_number": _houseNumberController.text.trim(),
      "sub_district": _subDistrictController.text.trim(),
      "district": _districtController.text.trim(),
      "province": _provinceController.text.trim(),
      "postal_code": _postalCodeController.text.trim(),
      "latitude": _currentPosition?.latitude,
      "longitude": _currentPosition?.longitude,
    };

    try {
      await widget.onSubmit(payload);
      _success("บันทึกสำเร็จ");
      setState(() => _hasChanged = false);
    } catch (_) {
      _error("เกิดข้อผิดพลาด กรุณาลองใหม่");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _success(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _buildForm(),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      children: [
        const Header(header: "ดูที่อยู่ของฉัน"),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _AddressTextArea(
                label: "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
                controller: _houseNumberController,
              ),
              _AddressTextField(
                label: "แขวง/ตำบล",
                controller: _subDistrictController,
              ),
              _AddressTextField(
                label: "เขต/อำเภอ",
                controller: _districtController,
              ),
              _AddressTextField(
                label: "จังหวัด",
                controller: _provinceController,
              ),
              _AddressTextField(
                label: "รหัสไปรษณีย์",
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: PrimaryButton(
            text: "ยืนยัน",
            onPressed: _hasChanged && !_isLoading ? _submit : null,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _AddressTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _AddressTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.colorTertiaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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

class _AddressTextArea extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _AddressTextArea({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.colorTertiaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'กรอกรายละเอียดที่อยู่',
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
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
