import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';


InputDecoration buildSmallPriceInputDecoration(
    String hint, {
      bool hasError = false,
    }) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.primaryBorder, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: hasError ? AppColors.colorError : AppColors.primaryBorderHover,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: hasError ? AppColors.colorError : AppColors.primaryBorderHover,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: hasError ? AppColors.colorError : AppColors.primaryBorderHover,
        width: 2,
      ),
    ),
  );
}