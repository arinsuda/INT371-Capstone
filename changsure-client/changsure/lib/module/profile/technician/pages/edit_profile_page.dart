import 'package:changsure/core/header.dart';
import 'package:changsure/core/profile/editProfile/phone_formatter.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/module/profile/technician/editProfile/province_checkbox_list.dart';
import 'package:changsure/module/profile/technician/editProfile/service_categories.dart';
import 'package:changsure/state/user_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:changsure/data/models/master_data_models.dart';
import '../../../../state/bottom_nav_provider.dart';
import '../../../../core/profile/editProfile/text_field.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';

import '../editProfile/text_area.dart';
import '../editProfile/search_bar.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController aboutController;
  final TextEditingController _searchController = TextEditingController();

  Map<int, bool> _selectedProvinces = {};
  Map<int, bool> _selectedServices = {};

  String _searchText = '';

  Map<int, String> _priceType = {};
  Map<int, TextEditingController> _minPriceControllers = {};
  Map<int, TextEditingController> _maxPriceControllers = {};
  Map<int, TextEditingController> _fixPriceControllers = {};

  File? _avatarFile;
  bool hasChanged = false;
  bool _isInitialized = false;

  String? _provinceError;
  String? _serviceError;
  Map<int, String?> _priceErrors = {};

  TechnicianModel? originalTech;
  List<ProvinceModel> allProvinces = [];
  List<ServiceCategoryModel> allCategories = [];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    aboutController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    aboutController.dispose();
    _searchController.dispose();

    for (final c in _minPriceControllers.values) {
      c.dispose();
    }
    for (final c in _maxPriceControllers.values) {
      c.dispose();
    }
    for (final c in _fixPriceControllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _avatarFile = File(pickedFile.path);
        });
        _checkChanged();
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _initializeData(
    List<ProvinceModel> provinces,
    List<ServiceCategoryModel> categories,
  ) {
    if (_isInitialized) return;

    final user = ref.read(userProvider);
    final tech = user?.technicianProfile;
    originalTech = tech;
    allProvinces = provinces;
    allCategories = categories;

    String firstName = '';
    String lastName = '';
    if (tech?.fullName != null) {
      final parts = tech!.fullName.split(' ');
      if (parts.isNotEmpty) firstName = parts[0];
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    nameController.text = tech?.firstName ?? firstName;
    lastNameController.text = tech?.lastName ?? lastName;
    emailController.text = tech?.email ?? '';
    aboutController.text = tech?.bio ?? '';

    String rawPhone = tech?.phone ?? '';
    if (rawPhone.isNotEmpty &&
        rawPhone.length == 10 &&
        !rawPhone.contains('-')) {
      phoneController.text =
          "${rawPhone.substring(0, 3)}-${rawPhone.substring(3, 6)}-${rawPhone.substring(6)}";
    } else {
      phoneController.text = rawPhone;
    }

    _selectedProvinces = {for (var p in provinces) p.id: false};
    if (tech?.provinces != null) {
      for (var userProv in tech!.provinces) {
        final match = provinces.firstWhere(
          (p) => p.nameTh == userProv.nameTh,
          orElse: () => ProvinceModel(id: -1, nameTh: ''),
        );
        if (match.id != -1) {
          _selectedProvinces[match.id] = true;
        }
      }
    }

    for (var category in categories) {
      for (var service in category.services) {
        final sId = service.id;

        _selectedServices[sId] = false;

        String masterType = service.defaultPrice.type == 'fixed'
            ? 'fix'
            : 'range';
        _priceType[sId] = masterType;

        _minPriceControllers[sId] = TextEditingController(
          text: service.defaultPrice.min?.toString() ?? '',
        );
        _maxPriceControllers[sId] = TextEditingController(
          text:
              service.defaultPrice.max?.toString() ??
              service.defaultPrice.value?.toString() ??
              '',
        );
        _fixPriceControllers[sId] = TextEditingController(
          text: service.defaultPrice.value?.toString() ?? '',
        );

        _minPriceControllers[sId]?.addListener(_checkChanged);
        _maxPriceControllers[sId]?.addListener(_checkChanged);
        _fixPriceControllers[sId]?.addListener(_checkChanged);
      }
    }

    if (tech?.services != null) {
      for (var userService in tech!.services) {
        final sId = userService.serviceId;

        if (_selectedServices.containsKey(sId)) {
          _selectedServices[sId] = true;

          String userType = userService.pricingType.toLowerCase() == 'fixed'
              ? 'fix'
              : 'range';
          _priceType[sId] = userType;

          if (userType == 'fix') {
            _fixPriceControllers[sId]?.text =
                userService.priceFixed?.toString() ?? '';

            _minPriceControllers[sId]?.text = '';
            _maxPriceControllers[sId]?.text = '';
          } else {
            _minPriceControllers[sId]?.text =
                userService.priceMin?.toString() ?? '';
            _maxPriceControllers[sId]?.text =
                userService.priceMax?.toString() ?? '';

            _fixPriceControllers[sId]?.text = '';
          }
        }
      }
    }

    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });
    nameController.addListener(_checkChanged);
    lastNameController.addListener(_checkChanged);
    emailController.addListener(_checkChanged);
    phoneController.addListener(_checkChanged);
    aboutController.addListener(_checkChanged);

    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAll()) return;

    final provinceIds = _selectedProvinces.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    List<Map<String, dynamic>> servicesData = [];

    for (var sId in _selectedServices.keys) {
      if (_selectedServices[sId] == true) {
        final type = _priceType[sId];
        final apiType = type == 'fix' ? 'FIXED' : 'RANGE';

        Map<String, dynamic> serviceMap = {
          "service_id": sId,
          "pricing_type": apiType,
          "category_id": _findCategoryId(sId),
        };

        if (type == 'fix') {
          serviceMap["price_fixed"] = double.tryParse(
            _fixPriceControllers[sId]?.text.replaceAll(',', '') ?? '0',
          );

          serviceMap["price_min"] = null;
          serviceMap["price_max"] = null;
        } else {
          serviceMap["price_min"] = double.tryParse(
            _minPriceControllers[sId]?.text.replaceAll(',', '') ?? '0',
          );
          serviceMap["price_max"] = double.tryParse(
            _maxPriceControllers[sId]?.text.replaceAll(',', '') ?? '0',
          );
          serviceMap["price_fixed"] = null;
        }
        servicesData.add(serviceMap);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final success = await ref
        .read(userProvider.notifier)
        .saveTechnicianProfile(
          firstName: nameController.text,
          lastName: lastNameController.text,
          phone: phoneController.text.replaceAll('-', ''),
          bio: aboutController.text,
          provinceIds: provinceIds,
          services: servicesData,
          avatarFile: _avatarFile,
        );

    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
        ref.read(bottomSubPageProvider.notifier).state = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
        );
      }
    }
  }

  int _findCategoryId(int serviceId) {
    for (var cat in allCategories) {
      for (var s in cat.services) {
        if (s.id == serviceId) return cat.id;
      }
    }
    return 0;
  }

  void _checkChanged() {
    if (!mounted) return;
    final changed = _hasProfileChanged();
    if (hasChanged != changed) {
      setState(() => hasChanged = changed);
    }
  }

  bool _hasProfileChanged() {
    if (originalTech == null) return false;

    if (_avatarFile != null) return true;

    if (nameController.text != (originalTech!.firstName)) return true;
    if (lastNameController.text != (originalTech!.lastName)) return true;
    if (emailController.text != (originalTech!.email ?? '')) return true;
    if (aboutController.text != (originalTech!.bio ?? '')) return true;

    String currentPhone = phoneController.text.replaceAll('-', '');
    String originalPhone = (originalTech!.phone ?? '').replaceAll('-', '');
    if (currentPhone != originalPhone) return true;

    final currentProvIds = _selectedProvinces.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final originalProvIds = originalTech!.provinces.map((e) => e.id).toSet();

    if (currentProvIds.length != originalProvIds.length ||
        !currentProvIds.containsAll(originalProvIds)) {
      return true;
    }

    final currentServiceIds = _selectedServices.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final originalServiceIds = originalTech!.services
        .map((e) => e.serviceId)
        .toSet();

    if (currentServiceIds.length != originalServiceIds.length ||
        !currentServiceIds.containsAll(originalServiceIds)) {
      return true;
    }

    for (final sId in currentServiceIds) {
      TechnicianService? originalSvc;

      try {
        originalSvc = originalTech!.services.firstWhere(
          (s) => s.serviceId == sId,
        );
      } catch (_) {
        return true;
      }

      if (originalSvc == null) return true;

      String currentType = (_priceType[sId] == 'fix') ? 'FIXED' : 'RANGE';

      if (currentType != originalSvc.pricingType) return true;

      if (currentType == 'FIXED') {
        double currentVal =
            double.tryParse(
              _fixPriceControllers[sId]?.text.replaceAll(',', '') ?? '',
            ) ??
            0.0;
        double originalVal = originalSvc.priceFixed ?? 0.0;
        if (currentVal != originalVal) return true;
      } else {
        double currentMin =
            double.tryParse(
              _minPriceControllers[sId]?.text.replaceAll(',', '') ?? '',
            ) ??
            0.0;
        double originalMin = originalSvc.priceMin ?? 0.0;
        if (currentMin != originalMin) return true;

        double currentMax =
            double.tryParse(
              _maxPriceControllers[sId]?.text.replaceAll(',', '') ?? '',
            ) ??
            0.0;
        double originalMax = originalSvc.priceMax ?? 0.0;
        if (currentMax != originalMax) return true;
      }
    }

    return false;
  }

  bool _validateAll() {
    String? newProvinceError = _selectedProvinces.values.any((v) => v)
        ? null
        : "กรุณาเลือกจังหวัดอย่างน้อย 1 แห่ง";

    bool hasService = _selectedServices.values.any((v) => v);
    String? newServiceError = hasService
        ? null
        : "กรุณาเลือกบริการอย่างน้อย 1 รายการ";

    Map<int, String?> newPriceErrors = {};
    for (var sId in _selectedServices.keys) {
      if (_selectedServices[sId] == true) {
        if (_priceType[sId] == "range") {
          final min = _minPriceControllers[sId]?.text.trim() ?? '';
          final max = _maxPriceControllers[sId]?.text.trim() ?? '';
          if (min.isEmpty || max.isEmpty) {
            newPriceErrors[sId] = "กรุณากรอกราคาให้ครบ";
          } else {
            final double minVal = double.tryParse(min) ?? 0;
            final double maxVal = double.tryParse(max) ?? 0;

            if (maxVal < minVal) {
              newPriceErrors[sId] = "Max ต้องมากกว่า Min";
            }
          }
        } else {
          final fix = _fixPriceControllers[sId]?.text.trim() ?? '';
          if (fix.isEmpty) {
            newPriceErrors[sId] = "กรุณากรอกราคา";
          }
        }
      }
    }

    setState(() {
      _provinceError = newProvinceError;
      _serviceError = newServiceError;
      _priceErrors = newPriceErrors;
    });

    return _provinceError == null &&
        _serviceError == null &&
        !_priceErrors.values.any((e) => e != null);
  }

  ImageProvider _getAvatarImage() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    }

    final url = originalTech?.avatarUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http') || url.startsWith('https')) {
        return NetworkImage(url);
      }
    }

    return const AssetImage('assets/image/Technician.png');
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    if (provincesAsync.isLoading || categoriesAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (provincesAsync.hasError || categoriesAsync.hasError) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("โหลดข้อมูลไม่สำเร็จ")),
      );
    }

    final provinces = provincesAsync.value!;
    final categories = categoriesAsync.value!;

    if (!_isInitialized) {
      _initializeData(provinces, categories);
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _getAvatarImage(),
                      onBackgroundImageError: (exception, stackTrace) {
                        print("🖼️ Image Load Error: $exception");
                      },
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
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
                  provinces,
                  _selectedProvinces,
                  (id, val) {
                    setState(() {
                      _selectedProvinces[id] = val;
                    });
                    _checkChanged();
                  },
                ),
              ),
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
                  children: categories.asMap().entries.map((entry) {
                    int index = entry.key;
                    ServiceCategoryModel cat = entry.value;

                    return ServiceCategory(
                      category: cat,
                      isFirst: index == 0,
                      isLast: index == categories.length - 1,
                      selectedServices: _selectedServices,
                      priceTypes: _priceType,
                      minPriceControllers: _minPriceControllers,
                      maxPriceControllers: _maxPriceControllers,
                      fixPriceControllers: _fixPriceControllers,
                      priceErrors: _priceErrors,
                      onServiceToggle: (id) {
                        setState(() {
                          _selectedServices[id] =
                              !(_selectedServices[id] ?? false);
                        });
                        _checkChanged();
                      },
                      onPriceTypeChanged: (id, type) {
                        setState(() {
                          _priceType[id] = type;
                        });
                        _checkChanged();
                      },
                      onPriceChange: () {
                        _checkChanged();
                      },
                    );
                  }).toList(),
                ),
              ),

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
                  onPressed: hasChanged ? _saveProfile : null,
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
