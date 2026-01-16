import 'package:flutter/material.dart';

class ActivityConstants {
  ActivityConstants._();

  static const Map<String, CategoryColorScheme> categoryColors = {
    "งานทาสี": CategoryColorScheme(
      text: Color(0xFFEB2F96),
      background: Color(0xFFFFF0F6),
      border: Color(0xFFFFADD2),
    ),
    "งานประปา": CategoryColorScheme(
      text: Color(0xFF36CFC9),
      background: Color(0xFFE6FFFB),
      border: Color(0xFF87E8DE),
    ),
    "งานไฟฟ้า": CategoryColorScheme(
      text: Color(0xFFFAAD14),
      background: Color(0xFFFFFBE6),
      border: Color(0xFFFFE58F),
    ),
    "งานซ่อมเครื่องใช้ไฟฟ้า": CategoryColorScheme(
      text: Color(0xFF722ED1),
      background: Color(0xFFF9F0FF),
      border: Color(0xFFD3ADF7),
    ),
  };

  static const CategoryColorScheme defaultColors = CategoryColorScheme(
    text: Colors.black,
    background: Color(0xFFE0E0E0),
    border: Color(0xFF9E9E9E),
  );

  static CategoryColorScheme getColors(String? categoryName) {
    if (categoryName == null) return defaultColors;
    return categoryColors[categoryName] ?? defaultColors;
  }

  static Color getTextColor(String? categoryName) {
    return getColors(categoryName).text;
  }

  static Color getBackgroundColor(String? categoryName) {
    return getColors(categoryName).background;
  }

  static Color getBorderColor(String? categoryName) {
    return getColors(categoryName).border;
  }

  static bool hasCustomColors(String categoryName) {
    return categoryColors.containsKey(categoryName);
  }

  static List<String> get availableCategories {
    return categoryColors.keys.toList();
  }

  static Map<String, Color> toLegacyFormat(String? categoryName) {
    final scheme = getColors(categoryName);
    return {
      "text": scheme.text,
      "background": scheme.background,
      "border": scheme.border,
    };
  }
}

class CategoryColorScheme {
  final Color text;
  final Color background;
  final Color border;

  const CategoryColorScheme({
    required this.text,
    required this.background,
    required this.border,
  });

  Map<String, Color> toMap() {
    return {"text": text, "background": background, "border": border};
  }
}

extension ActivityCategoryColorExtension on String {
  CategoryColorScheme get activityColors => ActivityConstants.getColors(this);

  Color get activityTextColor => ActivityConstants.getTextColor(this);

  Color get activityBackgroundColor =>
      ActivityConstants.getBackgroundColor(this);

  Color get activityBorderColor => ActivityConstants.getBorderColor(this);

  bool get hasActivityColors => ActivityConstants.hasCustomColors(this);

  Map<String, Color> get activityColorsLegacy =>
      ActivityConstants.toLegacyFormat(this);
}
