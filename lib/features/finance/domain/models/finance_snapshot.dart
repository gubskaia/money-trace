import 'package:money_trace/features/finance/domain/models/currency_converter.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.accounts,
    required this.categories,
    required this.templates,
    required this.transactions,
    required this.converter,
  });

  final List<FinanceAccount> accounts;
  final List<FinanceCategory> categories;
  final List<FinanceTemplate> templates;
  final List<FinanceTransaction> transactions;
  final CurrencyConverter converter;

  String get reportingCurrencyCode => converter.reportingCurrencyCode;

  double get totalBalance {
    return accounts.fold<double>(
      0,
      (sum, account) => sum + convertedAccountBalance(account),
    );
  }

  double get incomeThisMonth {
    return _transactionsForCurrentMonth
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(
          0,
          (sum, transaction) => sum + convertedTransactionAmount(transaction),
        );
  }

  double get expensesThisMonth {
    return _transactionsForCurrentMonth
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(
          0,
          (sum, transaction) => sum + convertedTransactionAmount(transaction),
        );
  }

  double get netFlowThisMonth => incomeThisMonth - expensesThisMonth;

  double get recurringMonthlyTotal {
    return templates.fold<double>(
      0,
      (sum, template) => sum + convertedTemplateMonthlyEstimate(template),
    );
  }

  double get recurringYearlyEstimate {
    return templates.fold<double>(
      0,
      (sum, template) => sum + convertedTemplateYearlyEstimate(template),
    );
  }

  List<FinanceTransaction> get recentTransactions {
    final sortedTransactions = List<FinanceTransaction>.of(transactions);
    sortedTransactions.sort(
      (left, right) => right.occurredAt.compareTo(left.occurredAt),
    );
    return sortedTransactions;
  }

  Map<String, double> get expenseByCategory {
    final totals = <String, double>{};

    for (final transaction in _transactionsForCurrentMonth) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }

      totals.update(
        transaction.categoryId,
        (current) => current + convertedTransactionAmount(transaction),
        ifAbsent: () => convertedTransactionAmount(transaction),
      );
    }

    return totals;
  }

  double convertAmount(
    double amount, {
    required String fromCurrencyCode,
    String? toCurrencyCode,
  }) {
    return converter.convert(
      amount,
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
    );
  }

  double convertedAccountBalance(
    FinanceAccount account, {
    String? toCurrencyCode,
  }) {
    return convertAmount(
      account.balance,
      fromCurrencyCode: account.currencyCode,
      toCurrencyCode: toCurrencyCode,
    );
  }

  double convertedTransactionAmount(
    FinanceTransaction transaction, {
    String? toCurrencyCode,
  }) {
    return convertAmount(
      transaction.amount,
      fromCurrencyCode: transaction.currencyCode,
      toCurrencyCode: toCurrencyCode,
    );
  }

  double convertedTemplateAmount(
    FinanceTemplate template, {
    String? toCurrencyCode,
  }) {
    return convertAmount(
      template.amount,
      fromCurrencyCode: template.currencyCode,
      toCurrencyCode: toCurrencyCode,
    );
  }

  double convertedTemplateMonthlyEstimate(
    FinanceTemplate template, {
    String? toCurrencyCode,
  }) {
    return convertAmount(
      template.monthlyEstimate,
      fromCurrencyCode: template.currencyCode,
      toCurrencyCode: toCurrencyCode,
    );
  }

  double convertedTemplateYearlyEstimate(
    FinanceTemplate template, {
    String? toCurrencyCode,
  }) {
    return convertAmount(
      template.yearlyEstimate,
      fromCurrencyCode: template.currencyCode,
      toCurrencyCode: toCurrencyCode,
    );
  }

  FinanceAccount? get primaryAccount {
    if (accounts.isEmpty) {
      return null;
    }
    return accounts.first;
  }

  List<FinanceCategory> categoriesOfKind(CategoryKind kind) {
    return categories.where((category) => category.kind == kind).toList();
  }

  FinanceAccount? findAccount(String id) {
    for (final account in accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  FinanceCategory? findCategory(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  List<FinanceTransaction> get _transactionsForCurrentMonth {
    final now = DateTime.now();
    return transactions.where((transaction) {
      return transaction.occurredAt.year == now.year &&
          transaction.occurredAt.month == now.month;
    }).toList();
  }
}
