import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/module/profile/technician/editProfile/sub_service_tile.dart';

class ServiceCategory extends StatelessWidget {
  final ServiceCategoryModel category;
  final Map<int, bool> selectedServices;
  final Map<int, String> priceTypes;
  final Map<int, TextEditingController> minPriceControllers;
  final Map<int, TextEditingController> maxPriceControllers;
  final Map<int, TextEditingController> fixPriceControllers;
  final Map<int, String?> priceErrors;

  final Function(int serviceId) onServiceToggle;
  final Function(int serviceId, String type) onPriceTypeChanged;
  final VoidCallback onPriceChange;

  final bool isFirst;
  final bool isLast;

  const ServiceCategory({
    super.key,
    required this.category,
    required this.selectedServices,
    required this.priceTypes,
    required this.minPriceControllers,
    required this.maxPriceControllers,
    required this.fixPriceControllers,
    required this.priceErrors,
    required this.onServiceToggle,
    required this.onPriceTypeChanged,
    required this.onPriceChange,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius radius = BorderRadius.zero;
    if (isFirst) radius = const BorderRadius.vertical(top: Radius.circular(8));
    if (isLast)
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
            category.catName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          iconColor: AppColors.primaryHover,
          collapsedIconColor: AppColors.primaryHover,
          backgroundColor: Colors.transparent,
          childrenPadding: EdgeInsets.zero,

          children: category.services.map((service) {
            final int sId = service.id;

            return buildSubServiceTile(
              service.serName,
              selectedServices[sId] ?? false,
              priceTypes[sId] ?? "range",
              minPriceControllers[sId]!,
              maxPriceControllers[sId]!,
              fixPriceControllers[sId]!,
              priceErrors[sId],

              (String name) => onServiceToggle(sId),
              (String name, String newType) => onPriceTypeChanged(sId, newType),
              onPriceChange,
            );
          }).toList(),
        ),
      ),
    );
  }
}
