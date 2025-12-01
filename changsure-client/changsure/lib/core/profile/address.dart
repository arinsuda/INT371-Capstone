import 'package:changsure/core/button/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/address/address_model.dart';
import '../theme.dart';
import '../header.dart';

/// --- Prevent postal code starting with 0 ---
class _PostCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;
    if (text.startsWith('0')) return oldValue;

    return newValue;
  }
}

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

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _houseNumberController;
  late final TextEditingController _subDistrictController;
  late final TextEditingController _districtController;
  late final TextEditingController _provinceController;
  late final TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _populateFields(widget.primaryAddress);
    _getLocation();
  }

  @override
  void didUpdateWidget(Address oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.primaryAddress != widget.primaryAddress) {
      _populateFields(widget.primaryAddress);
    }
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _houseNumberController = TextEditingController();
    _subDistrictController = TextEditingController();
    _districtController = TextEditingController();
    _provinceController = TextEditingController();
    _postalCodeController = TextEditingController();

    // track change
    for (final c in [
      _houseNumberController,
      _subDistrictController,
      _districtController,
      _provinceController,
      _postalCodeController,
    ]) {
      c.addListener(_onChanged);
    }
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

  void _onChanged() {
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

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      final pos = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  // ----------------------
  // VALIDATE (แบบ old version)
  // ----------------------
  bool _validateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return false;
    return true;
  }

  // ----------------------
  // SUBMIT
  // ----------------------
  Future<void> _submit() async {
    if (!_validateForm()) return;

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

  // ----------------------
  // UI
  // ----------------------
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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        children: [
          const Header(header: "ดูที่อยู่ของฉัน"),
          const SizedBox(height: 16),

          // Area
          _buildTextArea(
            "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
            _houseNumberController,
            validator: (v) {
              if (v == null || v.isEmpty) return "กรุณากรอกบ้านเลขที่";
              if (v.length > 500) return "บ้านเลขที่ต้องไม่เกิน 500 ตัวอักษร";
              return null;
            },
          ),

          _buildField(
            "แขวง/ตำบล",
            _subDistrictController,
            validator: (v) =>
                (v == null || v.isEmpty) ? "กรุณากรอกแขวง/ตำบล" : null,
          ),
          _buildField(
            "เขต/อำเภอ",
            _districtController,
            validator: (v) =>
                (v == null || v.isEmpty) ? "กรุณากรอกเขต/อำเภอ" : null,
          ),
          _buildField(
            "จังหวัด",
            _provinceController,
            validator: (v) =>
                (v == null || v.isEmpty) ? "กรุณากรอกจังหวัด" : null,
          ),
          _buildField(
            "รหัสไปรษณีย์",
            _postalCodeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
              _PostCodeFormatter(),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return "กรุณากรอกรหัสไปรษณีย์";
              if (!RegExp(r"^[1-9][0-9]{4}$").hasMatch(v)) {
                return "รหัสไปรษณีย์ต้องเป็นตัวเลข 5 หลัก และไม่ขึ้นต้นด้วย 0";
              }
              return null;
            },
          ),

          PrimaryButton(
            text: "ยืนยัน",
            onPressed: _hasChanged && !_isLoading ? _submit : null,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildField(
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
              fontSize: 12,
              color: AppColors.colorTertiaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
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
              fontSize: 12,
              color: AppColors.colorTertiaryText,
              fontWeight: FontWeight.w500,
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
            decoration: _inputDecoration().copyWith(
              hintText: 'กรอกรายละเอียดที่อยู่',
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        borderSide: const BorderSide(color: AppColors.primaryBorder, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.colorError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.colorError, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.colorError, fontSize: 12),
    );
  }
}
