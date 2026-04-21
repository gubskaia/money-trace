import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';

abstract final class DemoSeedData {
  static List<FinanceAccount> accounts() {
    return const [
      FinanceAccount(
        id: 'acc-main',
        name: 'Main',
        kind: AccountKind.card,
        balance: 2848,
        currencyCode: 'KZT',
        accentColorValue: 0xFF58BE83,
      ),
      FinanceAccount(
        id: 'acc-savings',
        name: 'Savings',
        kind: AccountKind.savings,
        balance: 15000,
        currencyCode: 'KZT',
        accentColorValue: 0xFF54BEB0,
      ),
      FinanceAccount(
        id: 'acc-cash',
        name: 'Cash',
        kind: AccountKind.cash,
        balance: 120,
        currencyCode: 'KZT',
        accentColorValue: 0xFFF1A533,
      ),
    ];
  }

  static List<FinanceCategory> categories() {
    return const [
      FinanceCategory(
        id: 'cat-salary',
        name: 'Salary',
        emoji: '💼',
        tone: CategoryTone.emerald,
        kind: CategoryKind.income,
      ),
      FinanceCategory(
        id: 'cat-freelance',
        name: 'Freelance',
        emoji: '💻',
        tone: CategoryTone.sky,
        kind: CategoryKind.income,
      ),
      FinanceCategory(
        id: 'cat-investment',
        name: 'Investment',
        emoji: '📈',
        tone: CategoryTone.plum,
        kind: CategoryKind.income,
      ),
      FinanceCategory(
        id: 'cat-gift',
        name: 'Gift',
        emoji: '🎁',
        tone: CategoryTone.amber,
        kind: CategoryKind.income,
      ),
      FinanceCategory(
        id: 'cat-refund',
        name: 'Refund',
        emoji: '🔄',
        tone: CategoryTone.sky,
        kind: CategoryKind.income,
      ),
      FinanceCategory(
        id: 'cat-other-income',
        name: 'Other',
        emoji: '💰',
        tone: CategoryTone.emerald,
        kind: CategoryKind.income,
      ),
      FinanceCategory(
        id: 'cat-food',
        name: 'Food',
        emoji: '🍕',
        tone: CategoryTone.amber,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-home',
        name: 'Housing',
        emoji: '🏠',
        tone: CategoryTone.coral,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-transport',
        name: 'Transport',
        emoji: '🚗',
        tone: CategoryTone.sky,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-shopping',
        name: 'Shopping',
        emoji: '🛍️',
        tone: CategoryTone.amber,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-entertainment',
        name: 'Entertainment',
        emoji: '🎬',
        tone: CategoryTone.plum,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-health',
        name: 'Health',
        emoji: '💊',
        tone: CategoryTone.coral,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-bills',
        name: 'Bills',
        emoji: '🧾',
        tone: CategoryTone.sky,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-education',
        name: 'Education',
        emoji: '📚',
        tone: CategoryTone.plum,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'cat-other-expense',
        name: 'Other',
        emoji: '📌',
        tone: CategoryTone.coral,
        kind: CategoryKind.expense,
      ),
    ];
  }

  static List<FinanceTemplate> templates() {
    return const [
      FinanceTemplate(
        id: 'tpl-netflix',
        title: 'Netflix',
        amount: 8,
        currencyCode: 'KZT',
        accountId: 'acc-main',
        categoryId: 'cat-entertainment',
        groupName: 'Subscriptions',
        interval: RecurrenceInterval.monthly,
        note: 'Monthly subscription',
      ),
      FinanceTemplate(
        id: 'tpl-spotify',
        title: 'Spotify',
        amount: 3,
        currencyCode: 'KZT',
        accountId: 'acc-main',
        categoryId: 'cat-entertainment',
        groupName: 'Subscriptions',
        interval: RecurrenceInterval.monthly,
      ),
      FinanceTemplate(
        id: 'tpl-electricity',
        title: 'Electricity',
        amount: 150,
        currencyCode: 'KZT',
        accountId: 'acc-main',
        categoryId: 'cat-bills',
        groupName: 'Utilities',
        interval: RecurrenceInterval.monthly,
      ),
      FinanceTemplate(
        id: 'tpl-internet',
        title: 'Internet',
        amount: 25,
        currencyCode: 'KZT',
        accountId: 'acc-main',
        categoryId: 'cat-bills',
        groupName: 'Utilities',
        interval: RecurrenceInterval.monthly,
      ),
      FinanceTemplate(
        id: 'tpl-gym',
        title: 'Gym membership',
        amount: 35,
        currencyCode: 'KZT',
        accountId: 'acc-main',
        categoryId: 'cat-health',
        groupName: 'Memberships',
        interval: RecurrenceInterval.monthly,
      ),
      FinanceTemplate(
        id: 'tpl-insurance',
        title: 'Car insurance',
        amount: 80,
        currencyCode: 'KZT',
        accountId: 'acc-main',
        categoryId: 'cat-bills',
        groupName: 'Insurance',
        interval: RecurrenceInterval.monthly,
      ),
    ];
  }

  static List<FinanceTransaction> transactions() {
    final now = DateTime.now();

    return [
      FinanceTransaction(
        id: 'tx-1',
        title: 'Monthly salary',
        amount: 4200,
        currencyCode: 'KZT',
        type: TransactionType.income,
        accountId: 'acc-main',
        categoryId: 'cat-salary',
        occurredAt: DateTime(now.year, now.month, 2, 9, 30),
        note: 'Core income',
      ),
      FinanceTransaction(
        id: 'tx-2',
        title: 'Rent payment',
        amount: 134,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-main',
        categoryId: 'cat-home',
        occurredAt: DateTime(now.year, now.month, 7, 10, 10),
      ),
      FinanceTransaction(
        id: 'tx-3',
        title: 'Dinner out',
        amount: 117,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-main',
        categoryId: 'cat-food',
        occurredAt: DateTime(now.year, now.month, 8, 20, 15),
      ),
      FinanceTransaction(
        id: 'tx-4',
        title: 'Freelance payout',
        amount: 950,
        currencyCode: 'KZT',
        type: TransactionType.income,
        accountId: 'acc-savings',
        categoryId: 'cat-freelance',
        occurredAt: DateTime(now.year, now.month, 10, 14, 20),
      ),
      FinanceTransaction(
        id: 'tx-5',
        title: 'Pharmacy',
        amount: 50,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-cash',
        categoryId: 'cat-health',
        occurredAt: DateTime(now.year, now.month, 11, 13, 15),
      ),
      FinanceTransaction(
        id: 'tx-6',
        title: 'Cinema tickets',
        amount: 18,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-main',
        categoryId: 'cat-entertainment',
        occurredAt: DateTime(now.year, now.month, 12, 20, 5),
      ),
      FinanceTransaction(
        id: 'tx-7',
        title: 'New headphones',
        amount: 45,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-main',
        categoryId: 'cat-shopping',
        occurredAt: DateTime(now.year, now.month, 12, 12, 20),
      ),
      FinanceTransaction(
        id: 'tx-8',
        title: 'Uber ride',
        amount: 4,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-main',
        categoryId: 'cat-transport',
        occurredAt: DateTime(now.year, now.month, 13, 11, 10),
      ),
      FinanceTransaction(
        id: 'tx-9',
        title: 'Grocery store',
        amount: 13,
        currencyCode: 'KZT',
        type: TransactionType.expense,
        accountId: 'acc-main',
        categoryId: 'cat-food',
        occurredAt: DateTime(now.year, now.month, 13, 18, 45),
      ),
    ];
  }
}
