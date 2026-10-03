import 'package:flutter/services.dart';

class MaxValueFormatter extends TextInputFormatter {
  final int max;

  const MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = int.tryParse(newValue.text);
    if (value == null || value <= max) return newValue;

    final text = max.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
