import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import '../../../mockDB/province.dart';
import '../../../mockDB/services_categories.dart';
import '../../../state/bottom_bar_state.dart';
import 'package:flutter/services.dart';

import '../../../state/profile_state.dart';
import '../../../state/province_state.dart';

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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  ImageProvider _buildProfileImage(BuildContext context) {
    final profile = context.read<ProfileState>();
    final tech = profile.technicianProfile;

    // 1) ไม่มีข้อมูลโปรไฟล์เลย → ใช้ default
    if (tech == null || tech.avatarUrl == null || tech.avatarUrl!.isEmpty) {
      return const AssetImage('assets/image/Technician.png');
    }

    // 2) มีรูป → โหลดตาม URL
    try {
      return NetworkImage(tech.avatarUrl!);
    } catch (_) {
      // 3) โหลดรูปไม่ได้ → ใช้ fallback
      return const AssetImage('assets/image/Technician.png');
    }
  }

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

  // Map<String, String?> _priceErrors = {};
  String _initialFirstname = '';
  String _initialLastname = '';
  String _initialEmail = '';
  String _initialPhone = '';
  String _initialBio = '';
  Map<String, bool> _initialProvinces = {};

  void _checkChanged() {
    bool changed = false;
    bool allPricesFilled = true;
    bool hasSelectedProvince = false;
    // bool hasSelectedServiceWithPrice = false;

    changed |= nameController.text.trim() != _initialFirstname;
    changed |= lastNameController.text.trim() != _initialLastname;
    changed |= emailController.text.trim() != _initialEmail;
    changed |= phoneController.text.trim() != _initialPhone;
    changed |= aboutController.text.trim() != _initialBio;

    hasSelectedProvince = _selectedProvinces.values.any((v) => v);
    for (var province in _selectedProvinces.keys) {
      if (_selectedProvinces[province] != _initialProvinces[province]) {
        changed = true;
        break;
      }
    }

    // for (var sub in _selectedServices.keys) {
    //   if (_selectedServices[sub] == true) {
    //     changed = true;
    //
    //     if (_priceType[sub] == "range") {
    //       final minText = _minPriceControllers[sub]?.text ?? '';
    //       final maxText = _maxPriceControllers[sub]?.text ?? '';
    //       if (minText.isEmpty || maxText.isEmpty) {
    //         allPricesFilled = false;
    //       } else {
    //         hasSelectedServiceWithPrice = true;
    //       }
    //     } else if (_priceType[sub] == "fix") {
    //       final fixText = _fixPriceControllers[sub]?.text ?? '';
    //       if (fixText.isEmpty) {
    //         allPricesFilled = false;
    //       } else {
    //         hasSelectedServiceWithPrice = true;
    //       }
    //     }
    //   }
    // }

    bool validationPassed = _validateAll();

    bool shouldEnable =
        changed &&
        hasSelectedProvince &&
        // hasSelectedServiceWithPrice &&
        // allPricesFilled &&
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
    // bool hasSelectedService = _selectedServices.values.any((v) => v);
    // String? newServiceError = hasSelectedService
    //     ? null
    //     : "กรุณาเลือกข้อมูลให้ครบถ้วน";

    // Validate Prices
    // Map<String, String?> newPriceErrors = {};
    // for (var sub in _selectedServices.keys) {
    //   if (_selectedServices[sub] == true) {
    //     if (_priceType[sub] == "range") {
    //       final minText = _minPriceControllers[sub]?.text.trim() ?? '';
    //       final maxText = _maxPriceControllers[sub]?.text.trim() ?? '';
    //
    //       if (minText.isEmpty || maxText.isEmpty) {
    //         newPriceErrors[sub] = "กรุณากรอกจำนวน Min และ Max ให้ครบถ้วน";
    //       } else if (minText.startsWith('0') && minText.length > 1) {
    //         newPriceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
    //       } else if (maxText.startsWith('0') && maxText.length > 1) {
    //         newPriceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
    //       } else {
    //         final min = int.tryParse(minText) ?? 0;
    //         final max = int.tryParse(maxText) ?? 0;
    //         if (max < min) {
    //           newPriceErrors[sub] = "Max ต้องมากกว่าหรือเท่ากับ Min";
    //         } else {
    //           newPriceErrors[sub] = null;
    //         }
    //       }
    //     } else if (_priceType[sub] == "fix") {
    //       final fixText = _fixPriceControllers[sub]?.text.trim() ?? '';
    //       if (fixText.isEmpty) {
    //         newPriceErrors[sub] = "กรุณากรอกราคา";
    //       } else if (fixText.startsWith('0') && fixText.length > 1) {
    //         newPriceErrors[sub] = "ราคาไม่สามารถเริ่มต้นด้วย 0";
    //       } else {
    //         newPriceErrors[sub] = null;
    //       }
    //     }
    //   }
    // }

    // Update state ถ้ามีการเปลี่ยนแปลง
    if (_provinceError != newProvinceError
    // ||
    // _serviceError != newServiceError ||
    // _priceErrors.toString() != newPriceErrors.toString()
    ) {
      setState(() {
        _provinceError = newProvinceError;
        // _serviceError = newServiceError;
        // _priceErrors = newPriceErrors;
      });
    } else {
      _provinceError = newProvinceError;
      // _serviceError = newServiceError;
      // _priceErrors = newPriceErrors;
    }

    // Return true ถ้าไม่มี error
    return _provinceError == null;
    // &&
    // _serviceError == null;
    // &&
    // !_priceErrors.values.any((error) => error != null
    // );
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

    // for (var category in mockServiceCategories) {
    //   for (var sub in category.subServices) {
    //     _selectedServices[sub] = false;
    //     _priceType[sub] = "range";
    //     _minPriceControllers[sub] = TextEditingController();
    //     _maxPriceControllers[sub] = TextEditingController();
    //     _fixPriceControllers[sub] = TextEditingController();
    //
    //     _minPriceControllers[sub]?.addListener(_checkChanged);
    //     _maxPriceControllers[sub]?.addListener(_checkChanged);
    //     _fixPriceControllers[sub]?.addListener(_checkChanged);
    //   }
    // }

    nameController.addListener(_checkChanged);
    lastNameController.addListener(_checkChanged);
    emailController.addListener(_checkChanged);
    phoneController.addListener(_checkChanged);
    aboutController.addListener(_checkChanged);

    Future.microtask(() async {
      final profile = context.read<ProfileState>();
      final provinces = context.read<ProvinceState>();

      await profile.loadProfile();
      await provinces.loadProvinces();

      final tech = profile.technicianProfile;

      print('🔍 Debug: tech = $tech');
      print('🔍 Debug: tech.firstname = ${tech?.firstname}');
      print('🔍 Debug: tech.lastname = ${tech?.lastname}');
      print('🔍 Debug: tech.email = ${tech?.email}');
      print('🔍 Debug: tech.phone = ${tech?.phone}');
      print('🔍 Debug: tech.bio = ${tech?.bio}');

      if (tech != null) {
        _initialFirstname = tech.firstname;
        _initialLastname = tech.lastname;
        _initialEmail = tech.email;
        _initialPhone = tech.phone;
        _initialBio = tech.bio;

        nameController.text = tech.firstname;
        lastNameController.text = tech.lastname;
        emailController.text = tech.email;
        phoneController.text = tech.phone;
        aboutController.text = tech.bio;

        print('🔍 Debug: nameController.text = ${nameController.text}');
        print('🔍 Debug: lastNameController.text = ${lastNameController.text}');

        // สร้าง Map ตอน initState หรือ load provinces
        _selectedProvinces = {
          for (var p in provinces.provinces ?? []) p.id.toString(): false,
        };
        _initialProvinces = {
          for (var p in provinces.provinces ?? []) p.id.toString(): false,
        };

        // โหลดข้อมูล user/province
        for (var p in provinces.provinces ?? []) {
          bool isSelected = tech.provinces.any((tp) => tp.id == p.id);
          _selectedProvinces[p.id.toString()] = isSelected;
          _initialProvinces[p.id.toString()] = isSelected;
        }

        // for (var service in tech.services) {
        //   _selectedServices[service.serviceName] = true;
        //   _priceType[service.serviceName] = service.pricingType;
        //
        //   if (service.pricingType == 'range') {
        //     _minPriceControllers[service.serviceName]?.text =
        //         service.priceMin?.toString() ?? '';
        //     _maxPriceControllers[service.serviceName]?.text =
        //         service.priceMax?.toString() ?? '';
        //   } else if (service.pricingType == 'fix') {
        //     _fixPriceControllers[service.serviceName]?.text =
        //         service.priceFixed?.toString() ?? '';
        //   }
        // }
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    final provinceState = context.watch<ProvinceState>();

    if (profile.loading || provinceState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _buildProfileImage(context),
                      onBackgroundImageError: (_, __) {},
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
                  // ในส่วน onPressed ของ PrimaryButton
                  onPressed: hasChanged
                      ? () async {
                          final profile = context.read<ProfileState>();
                          final provinceData = context.read<ProvinceState>();

                          print('🔍 กำลังบันทึก:');
                          print('  ชื่อ: ${nameController.text.trim()}');
                          print('  นามสกุล: ${lastNameController.text.trim()}');
                          print('  อีเมล: ${emailController.text.trim()}');
                          print('  เบอร์: ${phoneController.text.trim()}');
                          print('  เกี่ยวกับ: ${aboutController.text.trim()}');

                          // 1. บันทึกข้อมูลส่วนตัว
                          final selectedProvinceIds = _selectedProvinces.entries
                              .where((e) => e.value)
                              .map((e) => int.parse(e.key))
                              .toList();

                          await profile.updateProfile(
                            firstname: nameController.text.trim(),
                            lastname: lastNameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            bio: aboutController.text.trim(),
                          );

                          await profile.updateTechnicianProvinces(selectedProvinceIds);

                          // ⭐ 2. รวบรวมและบันทึก Services
                          // List<Map<String, dynamic>> servicesData = [];

                          // for (var subService in _selectedServices.keys) {
                          //   if (_selectedServices[subService] == true) {
                          //     Map<String, dynamic> serviceData = {
                          //       'service_name': subService,
                          //       'price_type': _priceType[subService],
                          //     };
                          //
                          //     if (_priceType[subService] == 'range') {
                          //       serviceData['min_price'] = int.parse(
                          //           _minPriceControllers[subService]!.text.trim()
                          //       );
                          //       serviceData['max_price'] = int.parse(
                          //           _maxPriceControllers[subService]!.text.trim()
                          //       );
                          //     } else if (_priceType[subService] == 'fix') {
                          //       serviceData['fix_price'] = int.parse(
                          //           _fixPriceControllers[subService]!.text.trim()
                          //       );
                          //     }
                          //
                          //     servicesData.add(serviceData);
                          //   }
                          // }

                          // ⭐ บันทึก Services
                          // final success = await profile.updateTechnicianServices(servicesData);

                          await profile.loadProfile();

                          print('🔍 โหลดข้อมูลใหม่แล้ว:');
                          print(
                            '  ชื่อใหม่: ${profile.technicianProfile?.firstname}',
                          );
                          print(
                            '  นามสกุลใหม่: ${profile.technicianProfile?.lastname}',
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("บันทึกสำเร็จ")),
                            );
                            Provider.of<BottomBarState>(
                              context,
                              listen: false,
                            ).closeSubPage();
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("เกิดข้อผิดพลาดในการบันทึก"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
    String? priceError = '';
    // String? priceError = _priceErrors[subService];

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
                            onChanged: (_) {
                              _checkChanged();
                            },
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
                              _checkChanged();
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
                                // _priceErrors[subService] = null;
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
          // _priceErrors[subService] = null;
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
