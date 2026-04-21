enum TransactionType { expense, income }

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.currencyCode,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.occurredAt,
    this.note = '',
  });

  final String id;
  final String title;
  final double amount;
  final String currencyCode;
  final TransactionType type;
  final String accountId;
  final String categoryId;
  final DateTime occurredAt;
  final String note;
}

extension TransactionTypeLabelX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
    }
  }
}
