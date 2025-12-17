import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/activity_editor_state.dart';

class ActivityCategoryDropdown extends ConsumerWidget {
  final int activityId;

  const ActivityCategoryDropdown({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityEditorProvider(activityId));
    final notifier = ref.read(activityEditorProvider(activityId).notifier);

    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    const Map<String, Map<String, Color>> kActivityColorMap = {
      "งานทาสี": {
        "text": Color(0xFFEB2F96),
        "background": Color(0xFFFFF0F6),
        "border": Color(0xFFFFADD2),
      },
      "งานประปา": {
        "text": Color(0xFF36CFC9),
        "background": Color(0xFFE6FFFB),
        "border": Color(0xFF87E8DE),
      },
      "งานไฟฟ้า": {
        "text": Color(0xFFFAAD14),
        "background": Color(0xFFFFFBE6),
        "border": Color(0xFFFFE58F),
      },
      "งานซ่อมเครื่องใช้ไฟฟ้า": {
        "text": Color(0xFF722ED1),
        "background": Color(0xFFF9F0FF),
        "border": Color(0xFFD3ADF7),
      },
    };

    final selectedCategory = state.selectedCategory;

    final defaultColors = {
      "text": Colors.black,
      "background": Colors.grey.shade200,
      "border": Colors.grey.shade400,
    };

    final colors = selectedCategory != null
        ? (kActivityColorMap[selectedCategory] ?? defaultColors)
        : null;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),

                child: categoriesAsync.when(
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => const SizedBox(
                    height: 100,
                    child: Center(child: Text('ไม่สามารถโหลดข้อมูลได้')),
                  ),
                  data: (categories) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,

                      children: categories.map((category) {
                        final categoryName = category.catName;
                        final itemColor =
                            kActivityColorMap[categoryName] ??
                            {"text": Colors.black};

                        return ListTile(
                          title: Text(
                            categoryName,
                            style: TextStyle(color: itemColor["text"]),
                          ),
                          onTap: () {
                            notifier.setService(category.id, categoryName);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            );
          },
        );
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors?["background"] ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: colors?["border"] ?? Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCategory ?? "เลือกหมวด",
              style: TextStyle(
                color: colors?["text"] ?? Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: colors?["text"] ?? Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
