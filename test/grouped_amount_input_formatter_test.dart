import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/utils/grouped_amount_input_formatter.dart';

void main() {
  test('formats grouped integer input while typing', () {
    const formatter = GroupedAmountInputFormatter();

    final formatted = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '1000000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );

    expect(formatted.text, '1 000 000');
    expect(formatted.selection.extentOffset, 9);
  });

  test('keeps decimal input and normalizes leading separator', () {
    const formatter = GroupedAmountInputFormatter();

    final formatted = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: ',5',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );

    expect(formatted.text, '0.5');
    expect(formatted.selection.extentOffset, 3);
  });

  test('parses grouped values with spaces', () {
    expect(GroupedAmountInputFormatter.parse('10 000'), 10000);
    expect(GroupedAmountInputFormatter.parse('1 000 000.50'), 1000000.5);
  });

  test('formats persisted values for editing', () {
    expect(GroupedAmountInputFormatter.formatValue(10000), '10 000');
    expect(GroupedAmountInputFormatter.formatValue(12500.5), '12 500.5');
  });
}
