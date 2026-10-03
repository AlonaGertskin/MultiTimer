import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multitimer/max_value_formatter.dart';

void main() {
  const formatter = MaxValueFormatter(59);

  TextEditingValue format(String text) => formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: text),
      );

  test('lets values up to the maximum through', () {
    expect(format('7').text, '7');
    expect(format('45').text, '45');
    expect(format('59').text, '59');
  });

  test('clamps bigger values to the maximum', () {
    expect(format('60').text, '59');
    expect(format('99').text, '59');
  });

  test('puts the cursor at the end after clamping', () {
    expect(format('75').selection, const TextSelection.collapsed(offset: 2));
  });

  test('leaves an empty field alone', () {
    expect(format('').text, '');
  });
}
