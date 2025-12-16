import 'package:flutter/material.dart';
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

  // Callbacks
  final Function(int serviceId, bool value) onServiceSelected;
  final Function(int serviceId, String type) onPriceTypeChanged;

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
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        category.catName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: category.services.map((service) {
        final sId = service.id;
        final isSelected = selectedServices[sId] ?? false;

        return Column(
          children: [
            CheckboxListTile(
              title: Text(service.serName),
              value: isSelected,
              activeColor: AppColors.primary,
              onChanged: (val) {
                onServiceSelected(sId, val ?? false);
              },
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Type Toggle
                    Row(
                      children: [
                        _buildPriceTypeChoice(sId, 'range', 'ช่วงราคา'),
                        const SizedBox(width: 8),
                        _buildPriceTypeChoice(sId, 'fix', 'ราคาเหมา'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Input Fields
                    if (priceTypes[sId] == 'range')
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceInput(
                              minPriceControllers[sId]!,
                              'เริ่มต้น',
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("-"),
                          ),
                          Expanded(
                            child: _buildPriceInput(
                              maxPriceControllers[sId]!,
                              'สูงสุด',
                            ),
                          ),
                        ],
                      )
                    else
                      _buildPriceInput(fixPriceControllers[sId]!, 'ราคาเหมา'),

                    // Error Message
                    if (priceErrors[sId] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          priceErrors[sId]!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  // Helper Widget (Private ภายในไฟล์นี้)
  Widget _buildPriceTypeChoice(int sId, String type, String label) {
    final isSelected = priceTypes[sId] == type;
    return GestureDetector(
      onTap: () => onPriceTypeChanged(sId, type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInput(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.all(10),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
