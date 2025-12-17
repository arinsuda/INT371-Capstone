import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../mockDB/province.dart';

Widget buildProvinceCheckboxList(
  BuildContext context, // 👈 เพิ่ม context
  String searchText,
  Map<String, bool> selectedProvinces,
  VoidCallback onChange, // 👈 ใช้ type ที่ถูกต้อง
) {
  List<String> filtered = mockProvinces
      .where((p) => p.toLowerCase().contains(searchText.toLowerCase()))
      .toList();

  List<String> checked =
      filtered.where((p) => selectedProvinces[p] == true).toList()..sort();

  List<String> unchecked =
      filtered.where((p) => selectedProvinces[p] != true).toList()..sort();

  List<String> displayList = [...checked, ...unchecked];

  if (searchText.isEmpty) {
    displayList = displayList.take(10).toList();
  }

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
              value: selectedProvinces[province] ?? false,
              onChanged: (val) {
                selectedProvinces[province] = val ?? false;
                onChange();
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
