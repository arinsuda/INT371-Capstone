import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';

class OtpInputWidget extends StatefulWidget {
  final Function(String)? onCompleted;

  const OtpInputWidget({super.key, this.onCompleted});

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  final int _length = 6;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(String value, int index) {

    // 🔥 ถ้ามีการพิมพ์
    if (value.isNotEmpty) {
      if (index < _length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        widget.onCompleted?.call(getOtpCode());
      }
    }

    // 🔥 ถ้ากดลบ (ค่าเป็นค่าว่าง)
    else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_length, (index) {
          return SizedBox(
            width: 45,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Focus(
                  // focusNode: _focusNodes[index],
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_controllers[index].text.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                        _controllers[index - 1].clear();
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    showCursor: false,
                    cursorWidth: 0,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < _length - 1) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          _focusNodes[index].unfocus();
                          widget.onCompleted?.call(getOtpCode());
                        }
                      }
                    },
                    decoration: InputDecoration(
                      counterText: "",
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // 🔥 เส้นขีดในกล่อง (ใช้ของเดิม)
                Positioned(
                  bottom: 18,
                  child: AnimatedBuilder(
                    animation: _focusNodes[index],
                    builder: (_, __) {
                      final isFocused =
                          _focusNodes[index].hasFocus;
                      return AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 200),
                        height: 2,
                        width: isFocused ? 16 : 0,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}