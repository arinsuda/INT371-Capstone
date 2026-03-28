import 'dart:convert';

import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/module/auth/technician/setup_technician_profile.dart';
import 'package:changsure/module/auth/technician/technician_register_step_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../data/models/users/users_model.dart';
import '../../../state/master_data_provider.dart';
import '../../../state/user_provider.dart';
import '../../profile/technician/editProfile/service_categories.dart';

class WorkTypeListPage extends ConsumerStatefulWidget {
  final String email;
  final String password;
  final String confirmPassword;
  final RegisterAddressModel address;
  final List<String>? consents;

  const WorkTypeListPage({
    super.key,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.address,
    required this.consents,
  });

  @override
  ConsumerState<WorkTypeListPage> createState() => _WorkTypeListPageState();
}

class _WorkTypeListPageState extends ConsumerState<WorkTypeListPage> {
  Map<int, bool> _selectedServices = {};
  Map<int, String> _priceType = {};
  Map<int, TextEditingController> _minPriceControllers = {};
  Map<int, TextEditingController> _maxPriceControllers = {};
  Map<int, TextEditingController> _fixPriceControllers = {};
  Map<int, String?> _priceErrors = {};
  bool _isInitialized = false;
  Set<int> _initializedCategoryIds = {};

  List<ServiceCategoryModel> allCategories = [];

  bool get canSubmit {
    if (!_selectedServices.values.any((v) => v)) return false;

    for (var id in _selectedServices.keys) {
      if (_selectedServices[id] == true) {
        if (_priceType[id] == "fix") {
          if ((_fixPriceControllers[id]?.text ?? '').isEmpty) return false;
        } else {
          if ((_minPriceControllers[id]?.text ?? '').isEmpty) return false;
          if ((_maxPriceControllers[id]?.text ?? '').isEmpty) return false;
        }
      }
    }

    return true;
  }

  void _initializeServices(List<ServiceCategoryModel> categories) {
    if (_isInitialized) return;

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
        )..addListener(() => setState(() {}));

        _maxPriceControllers[sId] = TextEditingController(
          text:
              service.defaultPrice.max?.toString() ??
              service.defaultPrice.value?.toString() ??
              '',
        )..addListener(() => setState(() {}));

        _fixPriceControllers[sId] = TextEditingController(
          text: service.defaultPrice.value?.toString() ?? '',
        )..addListener(() => setState(() {}));
      }
    }

    _isInitialized = true;
  }

  int _findCategoryId(int serviceId) {
    for (var cat in allCategories) {
      for (var s in cat.services) {
        if (s.id == serviceId) return cat.id;
      }
    }
    return 0;
  }

  void _saveServices() async {
    if (!_validateAll()) return;

    List<TechnicianServiceModel> servicesData = [];

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
            _fixPriceControllers[sId]?.text ?? '',
          );
        } else {
          serviceMap["price_min"] = double.tryParse(
            _minPriceControllers[sId]?.text ?? '',
          );
          serviceMap["price_max"] = double.tryParse(
            _maxPriceControllers[sId]?.text ?? '',
          );
        }

        servicesData.add(
          TechnicianServiceModel(
            serviceId: sId,
            pricingType: apiType,
            priceFixed: type == 'fix'
                ? double.tryParse(_fixPriceControllers[sId]?.text ?? '')
                : null,
            priceMin: type == 'range'
                ? double.tryParse(_minPriceControllers[sId]?.text ?? '')
                : null,
            priceMax: type == 'range'
                ? double.tryParse(_maxPriceControllers[sId]?.text ?? '')
                : null,
          ),
        );
      }
    }

    final registerData = ref.read(technicianRegisterDataProvider);

    // ✅ รวมข้อมูลทั้งหมดเป็น model
    final model = TechnicianRegisterModel(
      email: registerData.email ?? widget.email,
      password: registerData.password ?? widget.password,
      confirmPassword: registerData.confirmPassword ?? widget.confirmPassword,
      firstname: registerData.firstName ?? '',
      lastname: registerData.lastName ?? '',
      phone: registerData.phone ?? '',
      address: registerData.address ?? widget.address,
      provinceIds: registerData.provinceIds,
      consents: registerData.consents ?? widget.consents,
      services: servicesData,
    );

    // ✅ เรียก REGISTER API
    try {
      final result = await ref
          .read(technicianRegisterProvider.notifier)
          .register(model);

      final token = result?["pre_verified_token"];
      final technicianId = result?["technician_id"];

      print("TOKEN = $token");
      print("Technician ID = $technicianId");
      // ✅ save token
      ref.read(technicianRegisterDataProvider.notifier).update((state) {
        return TechnicianRegisterData(
          email: state.email,
          password: state.password,
          confirmPassword: state.confirmPassword,
          address: state.address,
          consents: state.consents,
          firstName: state.firstName,
          lastName: state.lastName,
          phone: state.phone,
          provinceIds: state.provinceIds,
          servicesData: state.servicesData,
          preVerifiedToken: token,
          technicianId: technicianId,
        );
      });

// ✅ success
      ref.read(technicianRegisterStepProvider.notifier).state = 3;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("สมัครไม่สำเร็จ: $e")),
      );
    }
  }

  bool _validateAll() {
    Map<int, String?> newPriceErrors = {};

    for (var sId in _selectedServices.keys) {
      if (_selectedServices[sId] == true) {
        if (_priceType[sId] == "range") {
          final min = _minPriceControllers[sId]?.text.trim() ?? '';
          final max = _maxPriceControllers[sId]?.text.trim() ?? '';

          if (min.isEmpty || max.isEmpty) {
            newPriceErrors[sId] = "กรุณากรอกราคาให้ครบ";
          } else {
            final minVal = double.tryParse(min) ?? 0;
            final maxVal = double.tryParse(max) ?? 0;

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
      _priceErrors = newPriceErrors;
    });

    return !_priceErrors.values.any((e) => e != null);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text("โหลดข้อมูลไม่สำเร็จ"),
      data: (categories) {
        allCategories = categories;

        _initializeServices(categories);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "ประเภทงานที่รับบริการ",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;

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
                    },

                    onPriceTypeChanged: (id, type) {
                      setState(() {
                        _priceType[id] = type;
                      });
                    },

                    onPriceChange: () {},
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TertiaryButton(
                      text: "ย้อนกลับ",
                      onPressed: () {
                        ref
                            .read(technicianRegisterStepProvider.notifier)
                            .state--;
                      },
                      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: "ยืนยัน",
                      onPressed: canSubmit ? _saveServices : null,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
