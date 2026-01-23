import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('-', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (text[0] != '0') {
      return oldValue;
    }

    String formatted = '';

    for (int i = 0; i < text.length && i < 10; i++) {
      if (i == 3 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}