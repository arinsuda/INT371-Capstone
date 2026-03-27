import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'package:changsure/data/models/master_data_models.dart';

Widget buildProvinceCheckboxList(
  BuildContext context,
  String searchText,
  List<ProvinceModel> provinces,
  Map<int, bool> selectedProvinces,
  Function(int, bool) onProvinceChanged,
) {
  List<ProvinceModel> filtered = provinces
      .where((p) => p.nameTh.toLowerCase().contains(searchText.toLowerCase()))
      .toList();

  List<ProvinceModel> checked =
      filtered.where((p) => selectedProvinces[p.id] == true).toList()
        ..sort((a, b) => a.nameTh.compareTo(b.nameTh));

  List<ProvinceModel> unchecked =
      filtered.where((p) => selectedProvinces[p.id] != true).toList()
        ..sort((a, b) => a.nameTh.compareTo(b.nameTh));

  List<ProvinceModel> displayList = [...checked, ...unchecked];

  if (displayList.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          "ไม่พบจังหวัดที่ค้นหา",
          style: TextStyle(color: AppColors.colorTertiaryText),
        ),
      ),
    );
  }

  return Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.55,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FE),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: displayList.length,
        padding: const EdgeInsets.all(4),
        itemBuilder: (context, index) {
          final province = displayList[index];

          return Theme(
            data: Theme.of(
              context,
            ).copyWith(unselectedWidgetColor: AppColors.primaryBorder),
            child: CheckboxListTile(
              title: Text(
                province.nameTh,
                style: const TextStyle(
                  color: AppColors.colorTertiaryText,
                  fontSize: 14,
                ),
              ),
              value: selectedProvinces[province.id] ?? false,
              onChanged: (val) {
                onProvinceChanged(province.id, val ?? false);
              },
              activeColor: const Color(0xFF3071C7),
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    ),
  );
}
