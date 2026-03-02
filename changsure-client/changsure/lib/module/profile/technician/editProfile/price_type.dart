import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

Widget buildPriceTypeChip(
    String type,
    String label,
    String currentType,
    Function(String) onTypeChange,
    ) {
  bool selected = currentType == type;

  return ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: selected
            ? AppColors.colorSecondaryText
            : AppColors.primaryBorderHover,
      ),
    ),
    selected: selected,
    onSelected: (_) => onTypeChange(type),
    backgroundColor: AppColors.colorSecondaryText,
    selectedColor: AppColors.primaryBorderHover,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.primarySecondaryBorder),
      borderRadius: BorderRadius.circular(6),
    ),
    showCheckmark: false,
  );
}
