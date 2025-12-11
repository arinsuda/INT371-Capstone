import 'package:changsure/module/profile/technician/editProfile/sub_service_tile.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../mockDB/services_categories.dart';

List<Widget> buildServiceCategories(
    BuildContext context,
    List<ServiceCategory> categories,
    Map<String, bool> selectedServices,
    Map<String, String> priceType,
    Map<String, TextEditingController> minPriceControllers,
    Map<String, TextEditingController> maxPriceControllers,
    Map<String, TextEditingController> fixPriceControllers,
    Map<String, String?> priceErrors,
    Function(String) onServiceToggle,
    Function(String, String) onPriceTypeChange, // ✅ เปลี่ยน signature รับ 2 parameters
    Function() onPriceChange,
    ) {
  return categories.asMap().entries.map((entry) {
    int index = entry.key;
    ServiceCategory category = entry.value;
    BorderRadius radius = BorderRadius.zero;

    if (index == 0) {
      radius = const BorderRadius.vertical(top: Radius.circular(8));
    } else if (index == categories.length - 1) {
      radius = const BorderRadius.vertical(bottom: Radius.circular(8));
    }

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
          childrenPadding: EdgeInsets.zero,
          children: category.subServices.map((sub) {
            return buildSubServiceTile(
              sub,
              selectedServices[sub] ?? false,
              priceType[sub] ?? "range",
              minPriceControllers[sub]!,
              maxPriceControllers[sub]!,
              fixPriceControllers[sub]!,
              priceErrors[sub],
              onServiceToggle,
              onPriceTypeChange,
              onPriceChange,
            );
          }).toList(),
        ),
      ),
    );
  }).toList();
}