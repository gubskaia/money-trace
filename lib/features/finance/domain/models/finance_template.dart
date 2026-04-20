enum RecurrenceInterval { weekly, monthly, yearly }

class FinanceTemplate {
  const FinanceTemplate({
    required this.id,
    required this.title,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.groupName,
    required this.interval,
    this.note = '',
  });

  final String id;
  final String title;
  final double amount;
  final String accountId;
  final String categoryId;
  final String groupName;
  final RecurrenceInterval interval;
  final String note;

  FinanceTemplate copyWith({
    String? id,
    String? title,
    double? amount,
    String? accountId,
    String? categoryId,
    String? groupName,
    RecurrenceInterval? interval,
    String? note,
  }) {
    return FinanceTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      groupName: groupName ?? this.groupName,
      interval: interval ?? this.interval,
      note: note ?? this.note,
    );
  }

  double get monthlyEstimate {
    return switch (interval) {
      RecurrenceInterval.weekly => amount * 52 / 12,
      RecurrenceInterval.monthly => amount,
      RecurrenceInterval.yearly => amount / 12,
    };
  }

  double get yearlyEstimate {
    return switch (interval) {
      RecurrenceInterval.weekly => amount * 52,
      RecurrenceInterval.monthly => amount * 12,
      RecurrenceInterval.yearly => amount,
    };
  }
}

extension RecurrenceIntervalLabelX on RecurrenceInterval {
  String get label {
    switch (this) {
      case RecurrenceInterval.weekly:
        return 'Weekly';
      case RecurrenceInterval.monthly:
        return 'Monthly';
      case RecurrenceInterval.yearly:
        return 'Yearly';
    }
  }

  String get shortLabel {
    switch (this) {
      case RecurrenceInterval.weekly:
        return '/wk';
      case RecurrenceInterval.monthly:
        return '/mo';
      case RecurrenceInterval.yearly:
        return '/yr';
    }
  }
}
