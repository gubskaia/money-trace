enum AccountKind { cash, card, savings, investment }

class FinanceAccount {
  const FinanceAccount({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.currencyCode,
    this.accentColorValue = 0xFF58BE83,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final double balance;
  final String currencyCode;
  final int accentColorValue;

  FinanceAccount copyWith({
    String? id,
    String? name,
    AccountKind? kind,
    double? balance,
    String? currencyCode,
    int? accentColorValue,
  }) {
    return FinanceAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
    );
  }
}

extension AccountKindLabelX on AccountKind {
  String get label {
    switch (this) {
      case AccountKind.cash:
        return 'Cash';
      case AccountKind.card:
        return 'Card';
      case AccountKind.savings:
        return 'Savings';
      case AccountKind.investment:
        return 'Investments';
    }
  }
}
