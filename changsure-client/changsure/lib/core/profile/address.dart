import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/address/address_model.dart';
import '../theme.dart';
import '../button/primaryButton.dart';
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
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    final address = widget.primaryAddress;

    _houseNumberController = TextEditingController(
      text: address?.houseNumber ?? "",
    );
    _subDistrictController = TextEditingController(
      text: address?.subDistrict ?? "",
    );
    _districtController = TextEditingController(text: address?.district ?? "");
    _provinceController = TextEditingController(text: address?.province ?? "");
    _postalCodeController = TextEditingController(
      text: address?.postalCode ?? "",
    );

    // Add listeners to detect changes
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

  void _onFieldChanged() {
    final address = widget.primaryAddress;

    final hasChanged =
        _houseNumberController.text != (address?.houseNumber ?? "") ||
        _subDistrictController.text != (address?.subDistrict ?? "") ||
        _districtController.text != (address?.district ?? "") ||
        _provinceController.text != (address?.province ?? "") ||
        _postalCodeController.text != (address?.postalCode ?? "");

    if (hasChanged != _hasChanged) {
      setState(() => _hasChanged = hasChanged);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showErrorSnackBar('กรุณาอนุญาตการเข้าถึงตำแหน่ง');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถรับตำแหน่งได้');
      }
    }
  }

  bool _validateForm() {
    if (_houseNumberController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกบ้านเลขที่');
      return false;
    }
    if (_subDistrictController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกแขวง/ตำบล');
      return false;
    }
    if (_districtController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกเขต/อำเภอ');
      return false;
    }
    if (_provinceController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกจังหวัด');
      return false;
    }
    if (_postalCodeController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกรหัสไปรษณีย์');
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        "house_number": _houseNumberController.text.trim(),
        "sub_district": _subDistrictController.text.trim(),
        "district": _districtController.text.trim(),
        "province": _provinceController.text.trim(),
        "postal_code": _postalCodeController.text.trim(),
        "latitude": widget.primaryAddress?.latitude,
        "longitude": widget.primaryAddress?.longitude,
      };

      await widget.onSubmit(payload);

      if (mounted) {
        _showSuccessSnackBar('บันทึกสำเร็จ');
        setState(() => _hasChanged = false);
      }
    } catch (e) {
      debugPrint('Error submitting address: $e');
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              children: [
                const Header(header: "ดูที่อยู่ของฉัน"),
                const SizedBox(height: 16),

                // Form Fields
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

                // Submit Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PrimaryButton(
                    text: "ยืนยัน",
                    onPressed: _hasChanged && !_isLoading
                        ? _handleSubmit
                        : null,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),

            // Loading Overlay
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
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
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
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
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
