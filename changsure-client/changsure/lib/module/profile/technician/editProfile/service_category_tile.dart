import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/data/models/master_data_models.dart';

class ServiceCategoryTile extends StatelessWidget {
  final ServiceCategoryModel category;
  final Map<int, bool> selectedServices;
  final Map<int, String> priceTypes;
  final Map<int, TextEditingController> minPriceControllers;
  final Map<int, TextEditingController> maxPriceControllers;
  final Map<int, TextEditingController> fixPriceControllers;
  final Map<int, String?> priceErrors;

  final Function(int serviceId, bool value) onServiceSelected;
  final Function(int serviceId, String type) onPriceTypeChanged;

  final bool isFirst;
  final bool isLast;

  const ServiceCategoryTile({
    super.key,
    required this.category,
    required this.selectedServices,
    required this.priceTypes,
    required this.minPriceControllers,
    required this.maxPriceControllers,
    required this.fixPriceControllers,
    required this.priceErrors,
    required this.onServiceSelected,
    required this.onPriceTypeChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius radius = BorderRadius.zero;
    if (isFirst) radius = const BorderRadius.vertical(top: Radius.circular(8));
    if (isLast)
      radius = const BorderRadius.vertical(bottom: Radius.circular(8));

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFE1EFFA),
        borderRadius: radius,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            category.catName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          iconColor: AppColors.primaryHover,
          collapsedIconColor:AppColors.primaryHover,
          backgroundColor: Colors.transparent,
          childrenPadding: EdgeInsets.zero,
          children: category.services.map((service) {
            return _buildSubServiceItem(service);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubServiceItem(ServiceModel service) {
    final sId = service.id;
    final isSelected = selectedServices[sId] ?? false;
    final priceError = priceErrors[sId];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBGHover : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (val) => onServiceSelected(sId, val ?? false),
            title: Text(
              service.serName,
              style: const TextStyle(fontSize: 14, color: AppColors.colorTertiaryText),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: AppColors.primaryBorderHover,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            dense: true,
            visualDensity: VisualDensity.compact,
          ),

          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (priceTypes[sId] == "range") ...[
                        Expanded(
                          child: _buildPriceInput(
                            minPriceControllers[sId]!,
                            "Min Price",
                            hasError: priceError != null,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_right_alt,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: _buildPriceInput(
                            maxPriceControllers[sId]!,
                            "Max Price",
                            hasError: priceError != null,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _buildPriceInput(
                            fixPriceControllers[sId]!,
                            "Price",
                            hasError: priceError != null,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildPriceTypeChip(sId, "range", "Range price"),
                      const SizedBox(width: 8),
                      _buildPriceTypeChip(sId, "fix", "Fix price"),
                    ],
                  ),

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
        ],
      ),
    );
  }

  Widget _buildPriceInput(
    TextEditingController controller,
    String hint, {
    bool hasError = false,
    TextAlign textAlign = TextAlign.start,
  }) {
    const primaryBlue = AppColors.primaryBorderHover;

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: textAlign,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.primaryBorder, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          filled: true,
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? AppColors.colorError : primaryBlue,
              width: 1.5,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: hasError ? AppColors.colorError : primaryBlue,
              width: 1.5,
            ),
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: hasError ? AppColors.colorError : primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTypeChip(int sId, String type, String label) {
    bool isSelected = priceTypes[sId] == type;
    const primaryBlue = Color(0xFF3071C7);

    return GestureDetector(
      onTap: () => onPriceTypeChanged(sId, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: primaryBlue, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : primaryBlue,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
