import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/data/local/sqlite_auth_repository.dart';
import 'package:money_trace/data/local/sqlite_money_trace_repository.dart';
import 'package:money_trace/features/finance/domain/models/currency_converter.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  test('persists transactions and account balances across reopen', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'money_trace_repo_test_',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final databasePath = p.join(tempDirectory.path, 'money_trace.db');
    final authRepository = await SqliteAuthRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    final repository = await SqliteMoneyTraceRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final session = await authRepository.register(
      fullName: 'Repo Test User',
      email: 'repo@test.dev',
      password: '1234',
      preferredCurrencyCode: 'USD',
    );
    final userId = session.userId;

    await repository.bootstrapUserWorkspace(
      userId: userId,
      accountName: 'Main Wallet',
      openingBalance: 1000,
      currencyCode: 'KZT',
    );

    final initialSnapshot = await repository.loadSnapshot(userId: userId);
    final expenseCategory =
        initialSnapshot.categories.where((category) {
          return category.kind == CategoryKind.expense;
        }).first;
    final account = initialSnapshot.accounts.first;
    final initialTransactionCount = initialSnapshot.transactions.length;
    final initialBalance = account.balance;

    await repository.addTransaction(
      userId: userId,
      transaction: FinanceTransaction(
        id: 'tx-persisted',
        title: 'Repository persistence test',
        amount: 99,
        currencyCode: account.currencyCode,
        type: TransactionType.expense,
        accountId: account.id,
        categoryId: expenseCategory.id,
        occurredAt: DateTime(2026, 4, 20, 12, 0),
      ),
    );
    await repository.addAccount(
      userId: userId,
      account: const FinanceAccount(
        id: 'acc-savings',
        name: 'Savings',
        kind: AccountKind.savings,
        balance: 300,
        currencyCode: 'EUR',
      ),
    );
    await repository.close();
    await authRepository.close();

    final reopenedRepository = await SqliteMoneyTraceRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    addTearDown(reopenedRepository.close);

    final reopenedSnapshot = await reopenedRepository.loadSnapshot(userId: userId);
    final reopenedAccount = reopenedSnapshot.findAccount(account.id);
    final converter = CurrencyConverter(
      reportingCurrencyCode: 'USD',
      ratesToBase: defaultExchangeRatesToBase,
    );
    final expectedTotalBalance =
        converter.convert(
          initialBalance - 99,
          fromCurrencyCode: account.currencyCode,
        ) +
        converter.convert(300, fromCurrencyCode: 'EUR');
    final persistedTransaction = reopenedSnapshot.transactions.firstWhere(
      (transaction) => transaction.id == 'tx-persisted',
    );

    expect(reopenedSnapshot.transactions.length, initialTransactionCount + 1);
    expect(reopenedSnapshot.accounts.length, 2);
    expect(reopenedSnapshot.reportingCurrencyCode, 'USD');
    expect(reopenedSnapshot.totalBalance, closeTo(expectedTotalBalance, 0.0001));
    expect(
      reopenedSnapshot.transactions.any(
        (transaction) => transaction.id == 'tx-persisted',
      ),
      isTrue,
    );
    expect(persistedTransaction.currencyCode, account.currencyCode);
    expect(reopenedAccount, isNotNull);
    expect(reopenedAccount!.balance, initialBalance - 99);
  });
}
