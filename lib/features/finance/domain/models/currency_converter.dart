class CurrencyConverter {
  CurrencyConverter({
    required String reportingCurrencyCode,
    this.baseCurrencyCode = exchangeRateBaseCurrencyCode,
    required Map<String, double> ratesToBase,
  }) : reportingCurrencyCode = reportingCurrencyCode.trim().toUpperCase(),
       ratesToBase = Map<String, double>.unmodifiable(<String, double>{
         exchangeRateBaseCurrencyCode: 1,
         for (final entry in ratesToBase.entries)
           entry.key.trim().toUpperCase(): entry.value,
       });

  final String reportingCurrencyCode;
  final String baseCurrencyCode;
  final Map<String, double> ratesToBase;

  double convert(
    double amount, {
    required String fromCurrencyCode,
    String? toCurrencyCode,
  }) {
    final normalizedFrom = fromCurrencyCode.trim().toUpperCase();
    final normalizedTo =
        (toCurrencyCode ?? reportingCurrencyCode).trim().toUpperCase();

    if (normalizedFrom == normalizedTo) {
      return amount;
    }

    final fromRate = _rateToBase(normalizedFrom);
    final toRate = _rateToBase(normalizedTo);
    return amount * fromRate / toRate;
  }

  double _rateToBase(String currencyCode) {
    final normalizedCode = currencyCode.trim().toUpperCase();
    final rate = ratesToBase[normalizedCode];
    if (rate != null) {
      return rate;
    }

    if (normalizedCode == baseCurrencyCode) {
      return 1;
    }

    throw StateError('Exchange rate for $normalizedCode is not configured.');
  }
}

const String exchangeRateBaseCurrencyCode = 'KZT';
const Map<String, double> defaultExchangeRatesToBase = <String, double>{
  'KZT': 1,
  'USD': 510,
  'EUR': 560,
  'GBP': 655,
  'JPY': 3.45,
  'RUB': 5.7,
  'CNY': 70.5,
  'BRL': 89,
};
