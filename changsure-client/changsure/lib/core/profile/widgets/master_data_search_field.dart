import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';

class MasterDataSearchField<T extends Object> extends StatefulWidget {
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
  State<MasterDataSearchField<T>> createState() =>
      _MasterDataSearchFieldState<T>();
}

class _MasterDataSearchFieldState<T extends Object>
    extends State<MasterDataSearchField<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOptionsVisible = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOptionsVisible = false;
  }

  void _showOptions() {
    if (widget.isLoading || widget.options.isEmpty || _isOptionsVisible) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isOptionsVisible = true;
  }

  void _toggleOptions() {
    if (_isOptionsVisible) {
      _removeOverlay();
    } else {
      widget.focusNode.requestFocus();
      _showOptions();
    }
  }

  List<T> _getFilteredOptions() {
    if (widget.controller.text.isEmpty) {
      return widget.options;
    }

    final query = widget.controller.text.toLowerCase();
    return widget.options.where((option) {
      return widget
          .displayStringForOption(option)
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Builder(
                builder: (context) {
                  final filteredOptions = _getFilteredOptions();

                  if (filteredOptions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'ไม่พบข้อมูล',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      return InkWell(
                        onTap: () {
                          widget.onSelected(option);
                          _removeOverlay();
                          widget.focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.displayStringForOption(option),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.colorTertiaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.isLoading,
              onChanged: (value) {
                widget.onChanged(value);

                // อัพเดท overlay เมื่อพิมพ์
                if (_isOptionsVisible) {
                  _removeOverlay();
                  _showOptions();
                }
              },
              onTap: () {
                if (!_isOptionsVisible) {
                  _showOptions();
                }
              },
              validator: (v) {
                if (v == null || v.isEmpty) return "กรุณาระบุ ${widget.label}";
                if (!widget.hasSelection && !widget.isLoading) {
                  return "กรุณาเลือกจากรายการ";
                }
                return null;
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _isOptionsVisible
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleOptions,
                      ),
                hintText: widget.isLoading
                    ? "กำลังโหลด..."
                    : "ค้นหา${widget.label}...",
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
            ),
          ],
        ),
      ),
    );
  }
}
