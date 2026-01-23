import 'package:flutter/material.dart';
import '../shared/constants/activity_constants.dart';

/// Category badge widget for displaying activity category with color
import 'package:flutter/material.dart';
import '../shared/constants/activity_constants.dart';

/// Category badge widget for displaying activity category with color
class ActivityCategoryBadge extends StatelessWidget {
  final String label;
  final CategoryColorScheme? colors;

  const ActivityCategoryBadge({super.key, required this.label, this.colors});

  /// Factory constructor using category name
  factory ActivityCategoryBadge.fromCategory(String categoryName) {
    return ActivityCategoryBadge(
      label: categoryName,
      colors: ActivityConstants.getColors(categoryName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = colors ?? ActivityConstants.defaultColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.text,
        ),
      ),
    );
  }
}
