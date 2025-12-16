import 'package:changsure/core/header.dart';
import 'package:changsure/core/profile/editProfile/phone_formatter.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/module/profile/technician/editProfile/province_selection_list.dart';
import 'package:changsure/module/profile/technician/editProfile/service_category_tile.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:flutter/services.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:changsure/data/models/master_data_models.dart';
import '../../../state/bottom_nav_provider.dart';
import '../../../core/profile/editProfile/text_field.dart';
import 'editProfile/text_area.dart';
import 'editProfile/search_bar.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController aboutController;
  final TextEditingController _searchController = TextEditingController();

  // State Variables
  Map<int, bool> _selectedProvinces = {};
  Map<int, bool> _selectedServices = {};

  String _searchText = '';

  Map<int, String> _priceType = {};
  Map<int, TextEditingController> _minPriceControllers = {};
  Map<int, TextEditingController> _maxPriceControllers = {};
  Map<int, TextEditingController> _fixPriceControllers = {};

  bool hasChanged = false;
  bool _isInitialized = false;

  // Errors
  String? _provinceError;
  String? _serviceError;
  Map<int, String?> _priceErrors = {};

  // Data
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

        _priceType[sId] = service.priceType == 'fixed' ? 'fix' : 'range';

        _minPriceControllers[sId] = TextEditingController(
          text: service.minPrice?.toString() ?? '',
        );
        _maxPriceControllers[sId] = TextEditingController(
          text: service.maxPrice?.toString() ?? '',
        );
        _fixPriceControllers[sId] = TextEditingController(
          text: service.maxPrice?.toString() ?? '',
        );

        _minPriceControllers[sId]?.addListener(_checkChanged);
        _maxPriceControllers[sId]?.addListener(_checkChanged);
        _fixPriceControllers[sId]?.addListener(_checkChanged);
      }
    }

    if (tech?.services != null) {
      for (var userService in tech!.services) {
        ServiceModel? match;

        for (var cat in categories) {
          try {
            match = cat.services.firstWhere(
              (s) => s.id == userService.serviceId,
            );

            if (match != null) break;
          } catch (_) {}
        }

        print("Services count: ${categories[0].services.length}");

        if (match != null) {
          final sId = match.id;
          _selectedServices[sId] = true;

          if (userService.pricingType == 'FIXED') {
            _priceType[sId] = 'fix';
            _fixPriceControllers[sId]?.text =
                userService.priceFixed?.toString() ?? '';
          } else {
            _priceType[sId] = 'range';
            _minPriceControllers[sId]?.text =
                userService.priceMin?.toString() ?? '';
            _maxPriceControllers[sId]?.text =
                userService.priceMax?.toString() ?? '';
          }
        }
      }
    }

    // Main Listeners
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAll()) return;

    String rawPhone = phoneController.text.replaceAll('-', '');

    // TODO: สร้าง Object เพื่อส่ง API
    // Map<String, dynamic> updateData = {
    //   "first_name": nameController.text,
    //   "phone": rawPhone, // ส่งแบบไม่มีขีด 0888888888
    //   "province_ids": _selectedProvinces.entries.where((e) => e.value).map((e) => e.key).toList(),
    //   ...
    // };

    print("Saving Phone Raw: $rawPhone");

    ref.read(bottomSubPageProvider.notifier).state = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย (Mock)')),
    );
  }

  void _checkChanged() {
    setState(() {
      hasChanged = true;
    });
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
          } else if (int.parse(max) < int.parse(min)) {
            newPriceErrors[sId] = "Max ต้องมากกว่า Min";
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

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    // Handle Loading & Error
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

    // Init Data Once
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

              // -----------------------------------------------------------
              // PROVINCES
              // -----------------------------------------------------------
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
                child: ProvinceSelectionList(
                  provinces: provinces,
                  selectedProvinces: _selectedProvinces,
                  searchText: _searchText,
                  onProvinceChanged: (id, val) {
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

              // -----------------------------------------------------------
              // SERVICES
              // -----------------------------------------------------------
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
                  children: categories.map((cat) {
                    return ServiceCategoryTile(
                      category: cat,
                      selectedServices: _selectedServices,
                      priceTypes: _priceType,
                      minPriceControllers: _minPriceControllers,
                      maxPriceControllers: _maxPriceControllers,
                      fixPriceControllers: _fixPriceControllers,
                      priceErrors: _priceErrors,

                      onServiceSelected: (id, val) {
                        setState(() {
                          _selectedServices[id] = val;
                        });
                        _checkChanged();
                      },

                      onPriceTypeChanged: (id, type) {
                        setState(() {
                          _priceType[id] = type;
                        });
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
