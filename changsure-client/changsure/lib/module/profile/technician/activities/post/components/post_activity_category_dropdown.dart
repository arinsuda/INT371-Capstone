import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/activity_editor_state.dart';

class PostActivityCategoryDropdown extends ConsumerWidget {
  const PostActivityCategoryDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = activityEditorProvider(0);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    const Map<String, Map<String, Color>> kActivityColorMap = {
      "ช่างทาสี": {
        "text": Color(0xFFEB2F96),
        "background": Color(0xFFFFF0F6),
        "border": Color(0xFFFFADD2),
      },
      "ช่างประปา": {
        "text": Color(0xFF36CFC9),
        "background": Color(0xFFE6FFFB),
        "border": Color(0xFF87E8DE),
      },
      "ช่างไฟฟ้า": {
        "text": Color(0xFFFAAD14),
        "background": Color(0xFFFFFBE6),
        "border": Color(0xFFFFE58F),
      },
      "ช่างซ่อมเครื่องใช้ไฟฟ้า": {
        "text": Color(0xFF722ED1),
        "background": Color(0xFFF9F0FF),
        "border": Color(0xFFD3ADF7),
      },
    };

    final selectedCategory = state.selectedCategory;

    final colors = selectedCategory != null
        ? kActivityColorMap[selectedCategory]
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
                  error: (e, s) => const SizedBox(
                    height: 50,
                    child: Center(child: Text("โหลดข้อมูลไม่สำเร็จ")),
                  ),
                  data: (categories) => Column(
                    mainAxisSize: MainAxisSize.min,

                    children: categories.map((category) {
                      final categoryName = category.catName;

                      final itemColor =
                          kActivityColorMap[categoryName] ??
                          {"text": Colors.black};

                      return ListTile(
                        title: Text(
                          categoryName,
                          style: TextStyle(
                            color: itemColor["text"] ?? Colors.black,
                          ),
                        ),
                        onTap: () {
                          notifier.setCategory(category.id, categoryName);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
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
