import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/mockDB/services_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/state/activity_editor_state.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:changsure/module/profile/technician/activities/shared/constants/activity_constants.dart';

class ActivityCategoryDropdown extends ConsumerWidget {
  final int activityId;

  const ActivityCategoryDropdown({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityEditorProvider(activityId));
    final notifier = ref.read(activityEditorProvider(activityId).notifier);
    final AsyncValue<List<ServiceCategoryModel>> categoriesAsync = ref.watch(
      serviceCategoriesProvider,
    );

    final selectedCategory = state.selectedCategory;

    final colors = selectedCategory != null
        ? ActivityConstants.toLegacyFormat(selectedCategory)
        : null;

    return GestureDetector(
      onTap: () => _showCategoryPicker(context, ref, categoriesAsync, notifier),
      child: _buildDropdownButton(selectedCategory, colors),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    AsyncValue categoriesAsync,
    dynamic notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: categoriesAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 100,
              child: Center(child: Text('ไม่สามารถโหลดข้อมูลได้')),
            ),
            data: (categories) => Column(
              mainAxisSize: MainAxisSize.min,
              children: categories.map<Widget>((ServiceCategoryModel category) {
                final categoryName = category.catName;
                final textColor = ActivityConstants.getTextColor(categoryName);

                return ListTile(
                  title: Text(categoryName, style: TextStyle(color: textColor)),
                  onTap: () {
                    notifier.setCategory(category.id, categoryName);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownButton(
    String? selectedCategory,
    Map<String, Color>? colors,
  ) {
    return Container(
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
    );
  }
}
