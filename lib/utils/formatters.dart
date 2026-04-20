import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _moneyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'KZT ',
    decimalDigits: 0,
  );

  static final NumberFormat _plainNumberFormatter = NumberFormat(
    '#,##0',
    'en_US',
  );

  static final DateFormat _isoFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');

  static String money(num value) => _moneyFormatter.format(value);

  static String groupedNumber(num value) {
    return _plainNumberFormatter.format(value);
  }

  static String compactMoney(num value) {
    final absoluteValue = value.abs();
    final sign = value < 0 ? '-' : '';

    if (absoluteValue >= 1000000) {
      return '$sign${_compactValue(absoluteValue / 1000000)}M';
    }

    if (absoluteValue >= 1000) {
      return '$sign${_compactValue(absoluteValue / 1000)}K';
    }

    return '$sign${_plainNumberFormatter.format(absoluteValue)}';
  }

  static String moneyDelta(num value) {
    final prefix = value >= 0 ? '+' : '-';
    return '$prefix${money(value.abs())}';
  }

  static String shortDateTime(DateTime value) {
    return _dateTimeFormatter.format(value);
  }

  static String isoDate(DateTime value) {
    return _isoFormatter.format(value);
  }

  static String _compactValue(num value) {
    final formatted = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }
}
