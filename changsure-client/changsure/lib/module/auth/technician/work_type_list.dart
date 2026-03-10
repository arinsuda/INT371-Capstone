import 'package:changsure/module/auth/technician/technician_register_step_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../state/master_data_provider.dart';
import '../../../state/user_provider.dart';
import '../../profile/technician/editProfile/service_categories.dart';

class WorkTypeListPage extends ConsumerStatefulWidget {
  const WorkTypeListPage({super.key});

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
  final _formKey = GlobalKey<FormState>();

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
        );

        _maxPriceControllers[sId] = TextEditingController(
          text: service.defaultPrice.max?.toString() ?? '',
        );

        _fixPriceControllers[sId] = TextEditingController(
          text: service.defaultPrice.value?.toString() ?? '',
        );
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

  void _saveServices() {
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

        servicesData.add(serviceMap);
      }
    }

    ref.read(technicianRegisterStepProvider.notifier).state = 3;
  }

  Widget _buildCategory(ServiceCategoryModel category) {
    final servicesAsync = ref.watch(servicesByCategoryProvider(category.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.catName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          servicesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => const Text("โหลด services ไม่สำเร็จ"),
            data: (services) {
              return Column(
                children: services.map((service) {
                  final checked = _selectedServices[service.id] ?? false;

                  return CheckboxListTile(
                    value: checked,
                    title: Text(service.serName),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        _selectedServices[service.id] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text("โหลดข้อมูลไม่สำเร็จ"),
      data: (categories) {
        if (!_isInitialized) {
          _initializeServices(categories);
        }

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
              child: PrimaryButton(
                text: "ยืนยัน",
                onPressed: canSubmit ? _saveServices : null,
                padding: EdgeInsetsGeometry.symmetric(vertical: 8),
              ),
            ),
          ],
        );
      },
    );
  }
}
