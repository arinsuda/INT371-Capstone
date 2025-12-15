import 'package:flutter/material.dart';
import 'package:changsure/data/models/master_data_models.dart';

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
        .where((p) => p.nameTh.contains(searchText))
        .toList();

    filtered.sort((a, b) {
      bool isSelectedA = selectedProvinces[a.id] ?? false;
      bool isSelectedB = selectedProvinces[b.id] ?? false;

      if (isSelectedA && !isSelectedB) return -1;
      if (!isSelectedA && isSelectedB) return 1;
      return a.id.compareTo(b.id);
    });

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: filtered.isEmpty
          ? const Center(child: Text("ไม่พบจังหวัดที่ค้นหา"))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                return CheckboxListTile(
                  title: Text(p.nameTh),
                  // ใช้ ID เป็น Key
                  value: selectedProvinces[p.id] ?? false,
                  activeColor: Theme.of(
                    context,
                  ).primaryColor, // ใช้ theme สีหลัก
                  onChanged: (val) {
                    onProvinceChanged(p.id, val ?? false);
                  },
                );
              },
            ),
    );
  }
}
