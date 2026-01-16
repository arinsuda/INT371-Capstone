import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';
import 'price_type.dart';
import 'small_price_input.dart';

Widget buildSubServiceTile(
    String subService,
    bool selected,
    String priceType,
    TextEditingController minCtrl,
    TextEditingController maxCtrl,
    TextEditingController fixCtrl,
    String? priceError,
    Function(String) onServiceToggle,
    Function(String, String) onPriceTypeChange,
    Function() onPriceChange,
    ) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: selected ? AppColors.primaryBGHover : AppColors.primaryBG,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: selected,
          onChanged: (_) => onServiceToggle(subService), // ✅ เรียก callback ที่มี setState แล้ว
          title: Text(
            subService,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.colorTertiaryText,
            ),
          ),
          controlAffinity: ListTileControlAffinity.trailing,
          activeColor: const Color(0xFF3071C7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),

        if (selected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// RANGE PRICE
                if (priceType == "range")
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          decoration: buildSmallPriceInputDecoration(
                            "Min Price",
                            hasError: priceError != null,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => onPriceChange(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.primaryBorderHover,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          decoration: buildSmallPriceInputDecoration(
                            "Max Price",
                            hasError: priceError != null,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => onPriceChange(),
                        ),
                      ),
                    ],
                  ),

                /// FIX PRICE
                if (priceType == "fix")
                  TextField(
                    controller: fixCtrl,
                    textAlign: TextAlign.right,
                    decoration: buildSmallPriceInputDecoration(
                      "Price",
                      hasError: priceError != null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onPriceChange(),
                  ),

                /// ERROR TEXT
                if (priceError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      priceError,
                      style: const TextStyle(
                        color: AppColors.colorError,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        /// PRICE TYPE CHIPS
        if (selected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Spacer(),
                buildPriceTypeChip(
                  "range",
                  "Range price",
                  priceType,
                      (newType) => onPriceTypeChange(subService, newType), // ✅ ส่ง subService ด้วย
                ),
                const SizedBox(width: 8),
                buildPriceTypeChip(
                  "fix",
                  "Fix price",
                  priceType,
                      (newType) => onPriceTypeChange(subService, newType), // ✅ ส่ง subService ด้วย
                ),
              ],
            ),
          ),
      ],
    ),
  );
}