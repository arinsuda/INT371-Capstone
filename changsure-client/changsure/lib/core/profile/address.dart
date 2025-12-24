import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import 'package:changsure/core/theme.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';

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
    this.initialLat,
    this.initialLng,
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
  final FocusNode _provinceFocusNode = FocusNode();

  int? _selectedProvinceId;
  LatLng? _selectedCoordinates;

  bool hasChanged = false;
  bool allValid = false;
  bool _isLoading = false;
  bool _isMapLoading = false;

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

    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedCoordinates = LatLng(widget.initialLat!, widget.initialLng!);
    }
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

  Future<LatLng?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 3));

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<LatLng?> _getSmartStartingPoint() async {
    try {
      if (subDistrictController.text.isNotEmpty &&
          districtController.text.isNotEmpty &&
          provinceController.text.isNotEmpty) {
        String query =
            "${subDistrictController.text} ${districtController.text} ${provinceController.text}";
        List<geo.Location> locs = await geo.locationFromAddress(query);
        if (locs.isNotEmpty)
          return LatLng(locs.first.latitude, locs.first.longitude);
      }

      if (districtController.text.isNotEmpty &&
          provinceController.text.isNotEmpty) {
        String query = "${districtController.text} ${provinceController.text}";
        List<geo.Location> locs = await geo.locationFromAddress(query);
        if (locs.isNotEmpty)
          return LatLng(locs.first.latitude, locs.first.longitude);
      }

      if (provinceController.text.isNotEmpty) {
        List<geo.Location> locs = await geo.locationFromAddress(
          provinceController.text,
        );
        if (locs.isNotEmpty)
          return LatLng(locs.first.latitude, locs.first.longitude);
      }
    } catch (e) {
      debugPrint("Smart search failed: $e");
    }
    return null;
  }

  void _openMapPicker() async {
    setState(() => _isMapLoading = true);

    LatLng? initialPoint;

    if (_selectedCoordinates != null) {
      initialPoint = _selectedCoordinates;
    } else {
      initialPoint = await _getSmartStartingPoint();
    }
    if (initialPoint == null) {
      initialPoint = await _determinePosition();
    }
    initialPoint ??= const LatLng(13.7649, 100.5383);

    if (initialPoint.latitude > 21 ||
        initialPoint.latitude < 5 ||
        initialPoint.longitude < 97 ||
        initialPoint.longitude > 106) {
      initialPoint = const LatLng(13.7649, 100.5383);
    }

    setState(() => _isMapLoading = false);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapPickerSheet(
        initialCenter: initialPoint!,
        onPicked: (pickedLatLng) {
          setState(() {
            _selectedCoordinates = pickedLatLng;
            hasChanged = true;
            _checkForm();
          });
        },
      ),
    );
  }

  void _checkForm() {
    final changed =
        houseNumberController.text != widget.houseNumber ||
        subDistrictController.text != widget.subDistrict ||
        districtController.text != widget.district ||
        provinceController.text != widget.province ||
        postCodeController.text != widget.postCode.toString() ||
        (_selectedCoordinates?.latitude != widget.initialLat ||
            _selectedCoordinates?.longitude != widget.initialLng);

    bool valid = _formKey.currentState?.validate() ?? false;
    if (_selectedProvinceId == null) valid = false;

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
        LatLng? finalCoords = _selectedCoordinates;

        if (finalCoords == null) {
          finalCoords = await _getSmartStartingPoint();
          finalCoords ??= await _determinePosition();
        }

        final updateData = {
          'house_number': houseNumberController.text,
          'sub_district': subDistrictController.text,
          'district': districtController.text,
          'province_id': _selectedProvinceId,
          'postal_code': postCodeController.text,
          'country': 'Thailand',
          'lat': finalCoords?.latitude,
          'lng': finalCoords?.longitude,
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
                      validator: (v) => (v == null || v.isEmpty)
                          ? "กรุณากรอกบ้านเลขที่"
                          : null,
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
                        if (v == null || v.isEmpty)
                          return "กรุณากรอกรหัสไปรษณีย์";
                        if (!RegExp(r"^[1-9][0-9]{4}$").hasMatch(v))
                          return "รหัสไปรษณีย์ต้องเป็นตัวเลข 5 หลัก";
                        return null;
                      },
                      onChanged: (_) => _checkForm(),
                    ),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.colorStroke),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedCoordinates != null
                                ? Icons.location_on
                                : Icons.location_off,
                            color: _selectedCoordinates != null
                                ? AppColors.colorError
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCoordinates != null
                                      ? "ปักหมุดตำแหน่งแล้ว"
                                      : "ยังไม่ได้ระบุตำแหน่ง",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_selectedCoordinates != null)
                                  Text(
                                    "${_selectedCoordinates!.latitude.toStringAsFixed(5)}, ${_selectedCoordinates!.longitude.toStringAsFixed(5)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          _isMapLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: _openMapPicker,
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 18,
                                  ),
                                  label: const Text("เปิดแผนที่"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
    required FocusNode focusNode,
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
            focusNode: focusNode,
            displayStringForOption: (option) => option.nameTh,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (isLoading) return [];
              if (textEditingValue.text.isEmpty) {
                return provinces;
              }
              final filtered = provinces.where((ProvinceModel option) {
                return option.nameTh.contains(textEditingValue.text);
              }).toList();
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
            onSelected: (ProvinceModel selection) {
              if (selection.id == -1) return;
              setState(() {
                _selectedProvinceId = selection.id;
                controller.text = selection.nameTh;
                _checkForm();
              });
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: fieldFocusNode,
                    enabled: !isLoading,
                    onChanged: (val) {
                      if (val.isEmpty) {
                        setState(() {
                          _selectedProvinceId = null;
                        });
                      }
                      _checkForm();
                    },
                    onTap: () {
                      if (textEditingController.text.isEmpty) {
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
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
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

class _MapPickerSheet extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng) onPicked;

  const _MapPickerSheet({required this.initialCenter, required this.onPicked});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  late MapController mapController;
  late LatLng currentCenter;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    currentCenter = widget.initialCenter;
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);

      if (latLng.latitude > 21 ||
          latLng.latitude < 5 ||
          latLng.longitude < 97 ||
          latLng.longitude > 106) {
        latLng = const LatLng(13.7649, 100.5383);
      }

      mapController.move(latLng, 16.0);
      setState(() => currentCenter = latLng);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: 15.0,
                onPositionChanged: (position, hasGesture) {
                  if (position.center != null) {
                    setState(() => currentCenter = position.center!);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.changsure.app',
                ),
              ],
            ),
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: AppColors.colorError,
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "เลื่อนแผนที่ให้หมุดตรงกับสถานที่จริง",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SafeArea(
              child: PrimaryButton(
                text: "ยืนยันตำแหน่งนี้",
                onPressed: () {
                  widget.onPicked(currentCenter);
                  Navigator.pop(context);
                },
              ),
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              mini: false,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
