import 'package:flutter/material.dart';
import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/core/theme.dart';

class ProvinceSelectionList extends StatelessWidget {
  final List<ProvinceModel> provinces;
  final Map<int, bool> selectedProvinces;
  final String searchText;
  final Function(int id, bool value) onProvinceChanged;

  const ProvinceSelectionList({
    super.key,
    required this.provinces,
    required this.selectedProvinces,
    required this.searchText,
    required this.onProvinceChanged,
  });

  @override
  Widget build(BuildContext context) {
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
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(8),

        /*
        border: Border.all(color: AppColors.primaryBorder),
        */
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final province = displayList[index];
            final isSelected = selectedProvinces[province.id] ?? false;

            return Theme(
              data: Theme.of(
                context,
              ).copyWith(unselectedWidgetColor: AppColors.colorTertiaryText),
              child: CheckboxListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide.none,
                ),
                title: Text(
                  province.nameTh,
                  style: const TextStyle(
                    color: AppColors.colorTertiaryText,
                    fontSize: 14,
                  ),
                ),
                value: isSelected,
                onChanged: (val) {
                  onProvinceChanged(province.id, val ?? false);
                },
                activeColor: const Color(0xFF3071C7),
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        ),
      ),
    );
  }
}
