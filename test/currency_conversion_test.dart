import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/features/finance/domain/models/currency_converter.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';

void main() {
  test('finance snapshot converts balances and aggregates into reporting currency', () {
    final converter = CurrencyConverter(
      reportingCurrencyCode: 'USD',
      ratesToBase: defaultExchangeRatesToBase,
    );
    final snapshot = FinanceSnapshot(
      accounts: const [
        FinanceAccount(
          id: 'acc-kzt',
          name: 'KZT Wallet',
          kind: AccountKind.card,
          balance: 5100,
          currencyCode: 'KZT',
        ),
        FinanceAccount(
          id: 'acc-eur',
          name: 'EUR Wallet',
          kind: AccountKind.savings,
          balance: 10,
          currencyCode: 'EUR',
        ),
      ],
      categories: const [
        FinanceCategory(
          id: 'cat-food',
          name: 'Food',
          emoji: '🍽️',
          tone: CategoryTone.amber,
          kind: CategoryKind.expense,
        ),
      ],
      templates: const [
        FinanceTemplate(
          id: 'tpl-1',
          title: 'Insurance',
          amount: 560,
          currencyCode: 'KZT',
          accountId: 'acc-kzt',
          categoryId: 'cat-food',
          groupName: 'Bills',
          interval: RecurrenceInterval.monthly,
        ),
      ],
      transactions: [
        FinanceTransaction(
          id: 'tx-1',
          title: 'Lunch',
          amount: 560,
          currencyCode: 'KZT',
          type: TransactionType.expense,
          accountId: 'acc-kzt',
          categoryId: 'cat-food',
          occurredAt: DateTime.now(),
        ),
      ],
      converter: converter,
    );
    final expectedTotalBalance =
        converter.convert(5100, fromCurrencyCode: 'KZT') +
        converter.convert(10, fromCurrencyCode: 'EUR');

    expect(snapshot.reportingCurrencyCode, 'USD');
    expect(snapshot.totalBalance, closeTo(expectedTotalBalance, 0.0001));
    expect(snapshot.expensesThisMonth, closeTo(560 / 510, 0.0001));
    expect(snapshot.recurringMonthlyTotal, closeTo(560 / 510, 0.0001));
  });
}
