import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _plainNumberFormatter = NumberFormat(
    '#,##0',
    'en_US',
  );

  static final DateFormat _isoFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');

  static String money(num value, {String currencyCode = 'KZT'}) {
    final formatted = _plainNumberFormatter.format(value);
    return currencyCode.isEmpty ? formatted : '$formatted $currencyCode';
  }

  static String groupedNumber(num value) {
    return _plainNumberFormatter.format(value);
  }

  static String compactMoney(num value, {String currencyCode = ''}) {
    final absoluteValue = value.abs();
    final sign = value < 0 ? '-' : '';
    late final String compactValue;

    if (absoluteValue >= 1000000) {
      compactValue = '$sign${_compactValue(absoluteValue / 1000000)}M';
    } else if (absoluteValue >= 1000) {
      compactValue = '$sign${_compactValue(absoluteValue / 1000)}K';
    } else {
      compactValue = '$sign${_plainNumberFormatter.format(absoluteValue)}';
    }

    return currencyCode.isEmpty ? compactValue : '$compactValue $currencyCode';
  }

  static String moneyDelta(num value, {String currencyCode = 'KZT'}) {
    final prefix = value >= 0 ? '+' : '-';
    final amount = _plainNumberFormatter.format(value.abs());
    return currencyCode.isEmpty
        ? '$prefix$amount'
        : '$prefix$amount $currencyCode';
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
