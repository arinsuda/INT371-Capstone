import 'package:changsure/module/auth/technician/technician_register_step_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/profile/editProfile/phone_formatter.dart';
import '../../../core/profile/editProfile/text_field.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../state/bottom_nav_provider.dart';
import '../../../state/master_data_provider.dart';
import '../../../state/user_provider.dart';
import '../../profile/technician/editProfile/province_checkbox_list.dart';
import '../../profile/technician/editProfile/search_bar.dart';

class TechnicianRegisterData {
  String? firstName;
  String? lastName;
  String? phone;
  List<int>? provinceIds;
  List<Map<String, dynamic>>? servicesData;

  TechnicianRegisterData({
    this.firstName,
    this.lastName,
    this.phone,
    this.provinceIds,
    this.servicesData
  });
}

final technicianRegisterDataProvider =
StateProvider<TechnicianRegisterData>((ref) {
  return TechnicianRegisterData();
});

class SetupTechnicianProfile extends ConsumerStatefulWidget {
  const SetupTechnicianProfile({super.key});

  @override
  ConsumerState<SetupTechnicianProfile> createState() =>
      _SetupTechnicianProfileState();
}

class _SetupTechnicianProfileState
    extends ConsumerState<SetupTechnicianProfile> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  final TextEditingController _searchController = TextEditingController();

  Map<int, bool> _selectedProvinces = {};
  String _searchText = '';
  String? _provinceError;
  bool _isInitialized = false;
  List<ProvinceModel> allProvinces = [];


  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _searchController.dispose();
  }

  void _initializeData(List<ProvinceModel> provinces) {
    if (_isInitialized) return;

    final user = ref.read(userProvider);
    final tech = user?.technicianProfile;
    allProvinces = provinces;

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

    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });

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


    final success = await ref
        .read(userProvider.notifier)
        .saveTechnicianProfile(
          firstName: nameController.text,
          lastName: lastNameController.text,
          phone: phoneController.text.replaceAll('-', ''),
          provinceIds: provinceIds,
          services: servicesData,
        );

    ref.read(technicianRegisterDataProvider).firstName = nameController.text;
    ref.read(technicianRegisterDataProvider).lastName = lastNameController.text;
    ref.read(technicianRegisterDataProvider).phone =
        phoneController.text.replaceAll('-', '');
    ref.read(technicianRegisterDataProvider).provinceIds = provinceIds;

    if (success) {
      ref.read(technicianRegisterStepProvider.notifier).state = 2;
    }
    // if (mounted) {
    //   if (success) {
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
    //     ref.read(bottomSubPageProvider.notifier).state = null;
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
    //     );
    //   }
    // }
  }

  bool _validateAll() {
    String? newProvinceError = _selectedProvinces.values.any((v) => v)
        ? null
        : "กรุณาเลือกจังหวัดอย่างน้อย 1 แห่ง";

    setState(() {
      _provinceError = newProvinceError;
    });

    return _provinceError == null;
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    if (provincesAsync.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (provincesAsync.hasError) {
      return Center(child: Text("โหลดข้อมูลไม่สำเร็จ"));
    }

    final provinces = provincesAsync.value!;

    if (!_isInitialized) {
      _initializeData(provinces);
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "จังหวัดที่รับบริการ",
              style: TextStyle(
                color: AppColors.colorTertiaryText,
                fontSize: 14,
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

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PrimaryButton(
              text: "ยืนยัน",
              onPressed:  _saveProfile ,
              padding: EdgeInsetsGeometry.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
