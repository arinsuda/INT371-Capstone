import 'package:flutter/services.dart';

class PostCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (text[0] == '0') return oldValue;
    return newValue;
  }
}
