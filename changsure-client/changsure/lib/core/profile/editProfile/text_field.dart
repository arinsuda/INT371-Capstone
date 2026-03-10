import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';

Widget buildTextField(
    String label,
    TextEditingController controller, {
      String? Function(String?)? validator,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
    }) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.colorTertiaryText,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.colorError,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBorder,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.colorError,
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.colorError,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}