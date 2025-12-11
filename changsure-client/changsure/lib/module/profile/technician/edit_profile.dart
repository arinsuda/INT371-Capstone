import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import '../../../mockDB/province.dart';
import '../../../mockDB/services_categories.dart';
import '../../../state/bottom_bar_state.dart';
import '../../../core/profile/editProfile/phone_formatter.dart';
import 'package:flutter/services.dart';
import '../../../core/profile/editProfile/text_field.dart';
import 'editProfile/price_type.dart';
import 'editProfile/province_checkbox_list.dart';
import 'editProfile/service_categories.dart';
import 'editProfile/small_price_input.dart';
import 'editProfile/text_area.dart';
import 'editProfile/search_bar.dart';

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
  final TextEditingController aboutController = TextEditingController(
    text:
        'ช่างไฟฟ้ามากประสบการณ์กว่า 10 ปี เชี่ยวชาญงานซ่อมไฟฟ้าและติดตั้งอุปกรณ์ภายในบ้าน',
  );
  final TextEditingController _searchController = TextEditingController();

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

    bool validationPassed = _validateAll();

    bool shouldEnable =
        changed &&
        hasSelectedProvince &&
        hasSelectedServiceWithPrice &&
        allPricesFilled &&
        validationPassed;

    if (shouldEnable != hasChanged) {
      setState(() {
        hasChanged = shouldEnable;
      });
    }
  }

  bool _validateAll() {
    // Validate Province
    String? newProvinceError = _selectedProvinces.values.any((v) => v)
        ? null
        : "กรุณาเลือกข้อมูลให้ครบถ้วน";

    // Validate Services
    bool hasSelectedService = _selectedServices.values.any((v) => v);
    String? newServiceError = hasSelectedService
        ? null
        : "กรุณาเลือกข้อมูลให้ครบถ้วน";

    // Validate Prices
    Map<String, String?> newPriceErrors = {};
    for (var sub in _selectedServices.keys) {
      if (_selectedServices[sub] == true) {
        if (_priceType[sub] == "range") {
          final minText = _minPriceControllers[sub]?.text.trim() ?? '';
          final maxText = _maxPriceControllers[sub]?.text.trim() ?? '';

          if (minText.isEmpty || maxText.isEmpty) {
            newPriceErrors[sub] = "กรุณากรอกจำนวน Min และ Max ให้ครบถ้วน";
          } else if (minText.startsWith('0') && minText.length > 1) {
            newPriceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
          } else if (maxText.startsWith('0') && maxText.length > 1) {
            newPriceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
          } else {
            final min = int.tryParse(minText) ?? 0;
            final max = int.tryParse(maxText) ?? 0;
            if (max < min) {
              newPriceErrors[sub] = "Max ต้องมากกว่าหรือเท่ากับ Min";
            } else {
              newPriceErrors[sub] = null;
            }
          }
        } else if (_priceType[sub] == "fix") {
          final fixText = _fixPriceControllers[sub]?.text.trim() ?? '';
          if (fixText.isEmpty) {
            newPriceErrors[sub] = "กรุณากรอกราคา";
          } else if (fixText.startsWith('0') && fixText.length > 1) {
            newPriceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
          } else {
            newPriceErrors[sub] = null;
          }
        }
      }
    }

    // Update state ถ้ามีการเปลี่ยนแปลง
    if (_provinceError != newProvinceError ||
        _serviceError != newServiceError ||
        _priceErrors.toString() != newPriceErrors.toString()) {
      setState(() {
        _provinceError = newProvinceError;
        _serviceError = newServiceError;
        _priceErrors = newPriceErrors;
      });
    } else {
      _provinceError = newProvinceError;
      _serviceError = newServiceError;
      _priceErrors = newPriceErrors;
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

              buildTextField(
                "ชื่อ",
                nameController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกชื่อ";
                  if (v.length < 2) return "ชื่อต้องมีอย่างน้อย 2 ตัวอักษร";
                  return null;
                },
              ),

              buildTextField(
                "นามสกุล",
                lastNameController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกนามสกุล";
                  return null;
                },
              ),

              buildTextField(
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

              buildTextField(
                "เบอร์โทร",
                phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  PhoneNumberFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกเบอร์โทร";
                  if (!RegExp(r"^[0-9]{3}-[0-9]{3}-[0-9]{4}$").hasMatch(v)) {
                    return "เบอร์โทรต้องมี 10 หลัก";
                  }
                  return null;
                },
              ),

              buildTextArea("เกี่ยวกับ", aboutController),

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
                child: buildProvinceSearchBar(_searchController),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: buildProvinceCheckboxList(
                  context,
                  _searchText,
                  _selectedProvinces,
                  () {
                    setState(() {}); // ✅ เพิ่ม setState เพื่อ rebuild UI
                    _checkChanged();
                  },
                ),
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
                child: Column(
                  children: buildServiceCategories(
                    context,
                    mockServiceCategories,
                    _selectedServices,
                    _priceType,
                    _minPriceControllers,
                    _maxPriceControllers,
                    _fixPriceControllers,
                    _priceErrors,
                    (sub) {
                      // ✅ แก้: เพิ่ม setState รอบนอกและเรียก _checkChanged หลัง setState
                      setState(() {
                        _selectedServices[sub] =
                            !(_selectedServices[sub] ?? false);
                      });
                      _checkChanged();
                    },
                    (sub, newType) {
                      // ✅ แก้: รับ parameter newType มาตรงๆ แทนการ toggle
                      setState(() {
                        _priceType[sub] = newType;
                      });
                      _checkChanged();
                    },
                    () {
                      // ✅ แก้: เพิ่ม setState ก่อนเรียก _checkChanged
                      setState(() {});
                      _checkChanged();
                    },
                  ),
                ),
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
}
