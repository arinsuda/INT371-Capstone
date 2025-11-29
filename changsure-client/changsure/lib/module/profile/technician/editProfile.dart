import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:changsure/core/button/primaryButton.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import '../../../mockDB/province.dart';
import '../../../mockDB/servicesCategories.dart';
import '../../../state/bottomBarState.dart';
import 'package:flutter/services.dart';

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (text[0] != '0') {
      return oldValue;
    }

    String formatted = '';

    for (int i = 0; i < text.length && i < 10; i++) {
      if (i == 3 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController(
    text: 'สมชาย',
  );
  final TextEditingController lastNameController = TextEditingController(
    text: 'ใจดี',
  );
  final TextEditingController emailController = TextEditingController(
    text: 'somchai@gmail.com',
  );
  final TextEditingController phoneController = TextEditingController(
    text: '088-888-8888',
  );
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController aboutController = TextEditingController(
    text:
        'ช่างไฟฟ้ามากประสบการณ์กว่า 10 ปี เชี่ยวชาญงานซ่อมไฟฟ้าและติดตั้งอุปกรณ์ภายในบ้าน',
  );

  Map<String, bool> _selectedProvinces = {};
  String _searchText = '';

  Map<String, bool> _selectedServices = {};
  Map<String, String> _priceType = {};
  Map<String, TextEditingController> _minPriceControllers = {};
  Map<String, TextEditingController> _maxPriceControllers = {};
  Map<String, TextEditingController> _fixPriceControllers = {};
  bool hasChanged = false;

  // ตัวแปรเก็บ error messages
  String? _provinceError;
  String? _serviceError;
  Map<String, String?> _priceErrors = {};

  void _checkChanged() {
    bool changed = false;
    bool allPricesFilled = true;
    bool hasSelectedProvince = false;
    bool hasSelectedServiceWithPrice = false;

    changed |= nameController.text != 'สมชาย';
    changed |= lastNameController.text != 'ใจดี';
    changed |= emailController.text != 'somchai@gmail.com';
    changed |= phoneController.text != '088-888-8888';
    changed |=
        aboutController.text !=
            'ช่างไฟฟ้ามากประสบการณ์กว่า 10 ปี เชี่ยวชาญงานซ่อมไฟฟ้าและติดตั้งอุปกรณ์ภายในบ้าน';

    hasSelectedProvince = _selectedProvinces.values.any((v) => v);
    changed |= hasSelectedProvince;

    for (var sub in _selectedServices.keys) {
      if (_selectedServices[sub] == true) {
        changed = true;

        if (_priceType[sub] == "range") {
          final minText = _minPriceControllers[sub]?.text ?? '';
          final maxText = _maxPriceControllers[sub]?.text ?? '';
          if (minText.isEmpty || maxText.isEmpty) {
            allPricesFilled = false;
          } else {
            hasSelectedServiceWithPrice = true;
          }
        } else if (_priceType[sub] == "fix") {
          final fixText = _fixPriceControllers[sub]?.text ?? '';
          if (fixText.isEmpty) {
            allPricesFilled = false;
          } else {
            hasSelectedServiceWithPrice = true;
          }
        }
      }
    }

    bool shouldEnable =
        changed &&
            hasSelectedProvince &&
            hasSelectedServiceWithPrice &&
            allPricesFilled;

    if (shouldEnable != hasChanged) {
      setState(() {
        hasChanged = shouldEnable;
      });
    }

    // ทำการ validate ทุกครั้งที่มีการเปลี่ยนแปลง
    _validateAll();
  }

  // เพิ่มฟังก์ชัน validate ทั้งหมด
  bool _validateAll() {
    // Validate Province
    _provinceError = _selectedProvinces.values.any((v) => v)
        ? null
        : "กรุณาเลือกข้อมูลให้ครบถ้วน";

    // Validate Services
    bool hasSelectedService = _selectedServices.values.any((v) => v);
    _serviceError = hasSelectedService ? null : "กรุณาเลือกข้อมูลให้ครบถ้วน";

    // Validate Prices
    _priceErrors.clear();
    for (var sub in _selectedServices.keys) {
      if (_selectedServices[sub] == true) {
        if (_priceType[sub] == "range") {
          final minText = _minPriceControllers[sub]?.text.trim() ?? '';
          final maxText = _maxPriceControllers[sub]?.text.trim() ?? '';

          if (minText.isEmpty || maxText.isEmpty) {
            _priceErrors[sub] = "กรุณากรอกจำนวน Min และ Max ให้ครบถ้วน";
          } else if (minText.startsWith('0') && minText.length > 1) {
            _priceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
          } else if (maxText.startsWith('0') && maxText.length > 1) {
            _priceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
          } else {
            final min = int.tryParse(minText) ?? 0;
            final max = int.tryParse(maxText) ?? 0;
            if (max < min) {
              _priceErrors[sub] = "Max ต้องมากกว่าหรือเท่ากับ Min";
            } else {
              _priceErrors[sub] = null;
            }
          }
        } else if (_priceType[sub] == "fix") {
          final fixText = _fixPriceControllers[sub]?.text.trim() ?? '';
          if (fixText.isEmpty) {
            _priceErrors[sub] = "กรุณากรอกราคา";
          } else if (fixText.startsWith('0') && fixText.length > 1) {
            _priceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
          } else {
            _priceErrors[sub] = null;
          }
        }
      }
    }

    // Return true ถ้าไม่มี error
    return _provinceError == null &&
        _serviceError == null &&
        !_priceErrors.values.any((error) => error != null);
  }

  @override
  void initState() {
    super.initState();

    _selectedProvinces = {for (var p in mockProvinces) p: false};

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });

    for (var category in mockServiceCategories) {
      for (var sub in category.subServices) {
        _selectedServices[sub] = false;
        _priceType[sub] = "range";
        _minPriceControllers[sub] = TextEditingController();
        _maxPriceControllers[sub] = TextEditingController();
        _fixPriceControllers[sub] = TextEditingController();

        _minPriceControllers[sub]?.addListener(_checkChanged);
        _maxPriceControllers[sub]?.addListener(_checkChanged);
        _fixPriceControllers[sub]?.addListener(_checkChanged);
      }
    }

    nameController.addListener(_checkChanged);
    lastNameController.addListener(_checkChanged);
    emailController.addListener(_checkChanged);
    phoneController.addListener(_checkChanged);
    aboutController.addListener(_checkChanged);
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
              Header(header: "แก้ไขโปรไฟล์"),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/image/Technician.png',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFE8E8E8),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                "ชื่อ",
                nameController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกชื่อ";
                  if (v.length < 2) return "ชื่อต้องมีอย่างน้อย 2 ตัวอักษร";
                  return null;
                },
              ),

              _buildTextField(
                "นามสกุล",
                lastNameController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกนามสกุล";
                  return null;
                },
              ),

              _buildTextField(
                "อีเมล",
                emailController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกอีเมล";
                  if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(v)) {
                    return "รูปแบบอีเมลไม่ถูกต้อง";
                  }
                  return null;
                },
              ),

              _buildTextField(
                "เบอร์โทร",
                phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _PhoneNumberFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกเบอร์โทร";
                  if (!RegExp(r"^[0-9]{3}-[0-9]{3}-[0-9]{4}$").hasMatch(v)) {
                    return "เบอร์โทรต้องมี 10 หลัก";
                  }
                  return null;
                },
              ),

              _buildTextArea("เกี่ยวกับ", aboutController),

              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "จังหวัดที่รับบริการ",
                  style: TextStyle(
                    color: AppColors.colorTertiaryText,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildProvinceSearchBar(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildProvinceCheckboxList(),
              ),
              // แสดง error สำหรับ Province
              if (_provinceError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    _provinceError!,
                    style: const TextStyle(
                      color: AppColors.colorError,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "ประเภทงานที่รับบริการ",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: _buildServiceCategories()),
              ),
              // แสดง error สำหรับ Service
              if (_serviceError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    _serviceError!,
                    style: const TextStyle(
                      color: AppColors.colorError,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PrimaryButton(
                  text: "บันทึกการแก้ไข",
                  onPressed: hasChanged
                      ? () {
                          // เช็ค Form validation ก่อน
                          if (!_formKey.currentState!.validate()) {
                            print("INVALID! Form fields มีปัญหา");
                            return;
                          }

                          // เช็ค Province และ Services validation
                          if (!_validateAll()) {
                            print("INVALID! Province หรือ Services มีปัญหา");
                            return;
                          }

                          // ผ่านทั้งหมด
                          print("VALID! พร้อมส่งข้อมูล");
                          Provider.of<BottomBarState>(
                            context,
                            listen: false,
                          ).closeSubPage();
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 24),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
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
                  width: 1.5,
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

  Widget _buildTextArea(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
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
            maxLength: 500,
            controller: controller,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
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

  Widget _buildProvinceSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้นหา...',
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 24),
        ],
      ),
    );
  }

  Widget _buildProvinceCheckboxList() {
    List<String> filtered = mockProvinces
        .where((p) => p.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
    List<String> checked =
        filtered.where((p) => _selectedProvinces[p] == true).toList()..sort();
    List<String> unchecked =
        filtered.where((p) => _selectedProvinces[p] != true).toList()..sort();
    List<String> displayList = [...checked, ...unchecked];
    if (_searchText.isEmpty) displayList = displayList.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: displayList.map((province) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(unselectedWidgetColor: AppColors.primaryBorder),
              child: CheckboxListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(
                    color: AppColors.primaryBorder,
                    width: 1,
                  ),
                ),
                title: Text(
                  province,
                  style: const TextStyle(
                    color: AppColors.colorTertiaryText,
                    fontSize: 14,
                  ),
                ),
                value: _selectedProvinces[province] ?? false,
                onChanged: (val) {
                  setState(() {
                    _selectedProvinces[province] = val ?? false;
                    _checkChanged();
                  });
                },
                activeColor: const Color(0xFF3071C7),
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildServiceCategories() {
    return mockServiceCategories.asMap().entries.map((entry) {
      int index = entry.key;
      ServiceCategory category = entry.value;
      BorderRadius radius = BorderRadius.zero;
      if (index == 0)
        radius = const BorderRadius.vertical(top: Radius.circular(8));
      if (index == mockServiceCategories.length - 1)
        radius = const BorderRadius.vertical(bottom: Radius.circular(8));

      return Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFE1EFFA),
          borderRadius: radius,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              category.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            iconColor: AppColors.primaryHover,
            collapsedIconColor: AppColors.primaryHover,
            backgroundColor: Colors.transparent,
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 0,
            ),
            children: category.subServices.map(_buildSubServiceItem).toList(),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSubServiceItem(String subService) {
    bool selected = _selectedServices[subService] ?? false;
    String? priceError = _priceErrors[subService];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryBGHover : AppColors.primaryBG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (val) {
              setState(() {
                _selectedServices[subService] = val ?? false;
                _checkChanged();
              });
            },
            title: Text(
              subService,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: const Color(0xFF3071C7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_priceType[subService] == "range") ...[
                        Expanded(
                          child: TextField(
                            controller: _minPriceControllers[subService],
                            decoration: _buildSmallPriceInputDecoration(
                              "Min Price",
                              hasError: priceError != null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.primaryBorderHover,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceControllers[subService],
                            decoration: _buildSmallPriceInputDecoration(
                              "Max Price",
                              hasError: priceError != null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              // ⭐ เคลียร์ error เมื่อพิมพ์
                              setState(() {
                                _priceErrors[subService] = null;
                              });
                            },
                          ),
                        ),
                      ],
                      if (_priceType[subService] == "fix")
                        Expanded(
                          child: TextField(
                            controller: _fixPriceControllers[subService],
                            textAlign: TextAlign.right,
                            decoration: _buildSmallPriceInputDecoration(
                              "Price",
                              hasError: priceError != null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              // ⭐ เคลียร์ error เมื่อพิมพ์
                              setState(() {
                                _priceErrors[subService] = null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  // ⭐ แสดง error สำหรับ price
                  if (priceError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        priceError,
                        style: const TextStyle(
                          color: AppColors.colorError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (selected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Spacer(),
                  _buildPriceTypeChip(subService, "range", "Range price"),
                  const SizedBox(width: 8),
                  _buildPriceTypeChip(subService, "fix", "Fix price"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildSmallPriceInputDecoration(
    String hint, {
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.primaryBorder, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: hasError ? AppColors.colorError : AppColors.primaryBorderHover,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: hasError ? AppColors.colorError : AppColors.primaryBorderHover,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: hasError ? AppColors.colorError : AppColors.primaryBorderHover,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildPriceTypeChip(String subService, String type, String label) {
    bool selected = _priceType[subService] == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected
              ? AppColors.colorSecondaryText
              : AppColors.primaryBorderHover,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _priceType[subService] = type;
          // ⭐ เคลียร์ราคาเมื่อเปลี่ยน type
          if (type == "fix") {
            _minPriceControllers[subService]?.clear();
            _maxPriceControllers[subService]?.clear();
          } else {
            _fixPriceControllers[subService]?.clear();
          }
          _priceErrors[subService] = null;
          _checkChanged();
        });
      },
      backgroundColor: AppColors.colorSecondaryText,
      selectedColor: AppColors.primaryBorderHover,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primarySecondaryBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      showCheckmark: false,
    );
  }
}
