import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../../core/profile/technicianCard.dart';
import '../../../../core/theme.dart';
import '../../../../mockDB/activities.dart';

class ActivitySection extends StatefulWidget {
  const ActivitySection({super.key});

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  String? selectedCategory;

  // สร้าง list ของ category จาก mockActivities
  List<String> get categories {
    final allCategories = mockActivities
        .map((e) => e.serviceCategoryName)
        .toSet()
        .toList();
    allCategories.sort(); // จัดเรียงตัวอักษรถ้าต้องการ
    return ["ทั้งหมด", ...allCategories];
  }

  @override
  Widget build(BuildContext context) {
    // filter activities ตาม selectedCategory
    final filteredActivities =
        (selectedCategory == null || selectedCategory == "ทั้งหมด")
        ? mockActivities
        : mockActivities
              .where((e) => e.serviceCategoryName.trim() == selectedCategory)
              .toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ผลงานช่าง",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: false,
                  value: selectedCategory,
                  hint: const Text(
                    "ทั้งหมด",
                    style: TextStyle(color: AppColors.primary), // สี hint
                  ),
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(
                              color: Color(0xFF737373),
                            ), // สีเมนูด้านใน
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                  selectedItemBuilder: (context) {
                    // ปรับ style ของตัวเลือกที่แสดงบนปุ่ม
                    return categories.map((cat) {
                      return Text(
                        cat,
                        style: const TextStyle(color: AppColors.primary),
                      );
                    }).toList();
                  },
                  buttonStyleData: ButtonStyleData(
                    padding: const EdgeInsets.symmetric(
                      horizontal:0,
                      vertical: 6,
                    ),
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBGHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    offset: const Offset(0, -10),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              final activity = filteredActivities[index];
              return TechnicianCard(
                id: activity.id,
                serviceCategoryName: activity.serviceCategoryName,
                description: activity.description,
                images: activity.images,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
