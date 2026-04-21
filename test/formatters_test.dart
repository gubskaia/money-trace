import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/utils/formatters.dart';

void main() {
  test('money appends currency code when provided', () {
    expect(AppFormatters.money(12345, currencyCode: 'KZT'), '12,345 KZT');
    expect(AppFormatters.money(12345, currencyCode: ''), '12,345');
  });

  test('moneyDelta includes sign and currency code', () {
    expect(
      AppFormatters.moneyDelta(2500, currencyCode: 'USD'),
      '+2,500 USD',
    );
    expect(
      AppFormatters.moneyDelta(-2500, currencyCode: 'USD'),
      '-2,500 USD',
    );
  });

  test('compactMoney keeps compact suffix and appends currency code', () {
    expect(
      AppFormatters.compactMoney(1000000, currencyCode: 'KZT'),
      '1M KZT',
    );
    expect(
      AppFormatters.compactMoney(-1200, currencyCode: 'EUR'),
      '-1.2K EUR',
    );
  });
}
