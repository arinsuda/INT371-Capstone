import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';

class MasterDataSearchField<T extends Object> extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<T> options;
  final bool isLoading;
  final FocusNode focusNode;

  final bool hasSelection;

  final String Function(T) displayStringForOption;

  final ValueChanged<T> onSelected;

  final ValueChanged<String> onChanged;

  const MasterDataSearchField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    required this.isLoading,
    required this.focusNode,
    required this.hasSelection,
    required this.displayStringForOption,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          RawAutocomplete<T>(
            textEditingController: controller,
            focusNode: focusNode,
            displayStringForOption: displayStringForOption,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (isLoading) return const Iterable.empty();

              // ถ้าไม่พิมพ์อะไร ให้โชว์ทั้งหมด (dropdown behavior)
              if (textEditingValue.text.isEmpty) return options;

              final q = textEditingValue.text.toLowerCase();
              return options.where((T option) {
                return displayStringForOption(option).toLowerCase().contains(q);
              });
            },
            onSelected: onSelected,
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  void openOptions() {
                    if (isLoading || options.isEmpty) return;

                    // ให้ field ได้ focus ก่อน
                    fieldFocusNode.requestFocus();

                    // บังคับให้ RawAutocomplete rebuild overlay
                    // โดย "เปลี่ยน selection" แม้ text เดิม
                    final text = textEditingController.text;
                    textEditingController.selection =
                        const TextSelection.collapsed(offset: 0);
                    textEditingController.selection = TextSelection.collapsed(
                      offset: text.length,
                    );
                  }

                  return TextFormField(
                    controller: textEditingController,
                    focusNode: fieldFocusNode,
                    enabled: !isLoading,
                    onChanged: onChanged,

                    // กดที่ช่อง -> เปิดรายการทั้งหมด
                    onTap: openOptions,

                    validator: (v) {
                      if (v == null || v.isEmpty) return "กรุณาระบุ $label";
                      if (!hasSelection && !isLoading)
                        return "กรุณาเลือกจากรายการ";
                      return null;
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),

                      // เปลี่ยนเป็น IconButton เพื่อกดได้จริง
                      suffixIcon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                              onPressed: openOptions,
                            ),

                      hintText: isLoading ? "กำลังโหลด..." : "ค้นหา$label...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorStroke,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorStroke,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBorder,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.colorError,
                          width: 1,
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
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<T> onSelectedFromAutocomplete,
                  Iterable<T> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final T option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelectedFromAutocomplete(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Text(
                                  displayStringForOption(option),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }
}
 