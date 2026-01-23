import 'package:flutter/material.dart';

Widget buildProvinceSearchBar(TextEditingController controller) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD9D9D9)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'ค้นหา...',
              hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 24),
      ],
    ),
  );
}
