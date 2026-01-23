import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';

Widget buildTextArea(String label, TextEditingController controller) {
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
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          maxLength: 500,
          controller: controller,
          maxLines: 5,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'เขียนรายละเอียดเกี่ยวกับตัวคุณ...',
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBorder,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}