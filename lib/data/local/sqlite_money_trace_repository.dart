import 'package:money_trace/data/demo/demo_seed_data.dart';
import 'package:money_trace/data/local/money_trace_database.dart';
import 'package:money_trace/features/finance/domain/models/currency_converter.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/features/finance/domain/repositories/money_trace_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

class SqliteMoneyTraceRepository implements MoneyTraceRepository {
  SqliteMoneyTraceRepository._(this._database);

  final Database _database;

  static Future<SqliteMoneyTraceRepository> open({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) async {
    final database = await openMoneyTraceDatabase(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
    );
    return SqliteMoneyTraceRepository._(database);
  }

  Future<void> close() {
    return _database.close();
  }

  @override
  Future<FinanceSnapshot> loadSnapshot({required String userId}) async {
    final accounts = await _database.query(
      accountsTable,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'sort_order ASC',
    );
    final categories = await _database.query(
      categoriesTable,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'sort_order ASC',
    );
    final templates = await _database.query(
      recurringTemplatesTable,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'sort_order ASC',
    );
    final transactions = await _database.query(
      transactionsTable,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'sort_order ASC',
    );
    final reportingCurrencyCode = await _loadReportingCurrencyCode(userId);
    final exchangeRates = await _loadExchangeRates();

    return FinanceSnapshot(
      accounts: accounts.map(_accountFromRow).toList(growable: false),
      categories: categories.map(_categoryFromRow).toList(growable: false),
      templates: templates.map(_templateFromRow).toList(growable: false),
      transactions: transactions
          .map(_transactionFromRow)
          .toList(growable: false),
      converter: CurrencyConverter(
        reportingCurrencyCode: reportingCurrencyCode,
        ratesToBase: exchangeRates,
      ),
    );
  }

  @override
  Future<void> bootstrapUserWorkspace({
    required String userId,
    required String accountName,
    required double openingBalance,
    required String currencyCode,
  }) async {
    await _database.transaction((transactionDb) async {
      final existingAccounts = await _countRows(
        transactionDb,
        accountsTable,
        userId: userId,
      );
      if (existingAccounts > 0) {
        return;
      }

      final categories = DemoSeedData.categories();
      for (var index = 0; index < categories.length; index++) {
        await transactionDb.insert(
          categoriesTable,
          _categoryToRow(
            userId,
            categories[index],
            sortOrder: index,
          ),
        );
      }

      await transactionDb.insert(
        accountsTable,
        _accountToRow(
          userId,
          FinanceAccount(
            id: 'acc-main',
            name: accountName.trim(),
            kind: AccountKind.card,
            balance: openingBalance,
            currencyCode: currencyCode.trim().toUpperCase(),
          ),
          sortOrder: 0,
        ),
      );
    });
  }

  @override
  Future<void> addTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    await _database.transaction((transactionDb) async {
      final sortOrder = await _nextSortOrder(
        transactionDb,
        transactionsTable,
        userId: userId,
      );
      await transactionDb.insert(
        transactionsTable,
        _transactionToRow(userId, transaction, sortOrder: sortOrder),
      );

      final accountRow = await _loadAccountRow(
        transactionDb,
        userId: userId,
        accountId: transaction.accountId,
      );
      if (accountRow == null) {
        throw StateError('Account not found.');
      }

      final categoryExists = await _rowExists(
        transactionDb,
        categoriesTable,
        userId: userId,
        id: transaction.categoryId,
      );
      if (!categoryExists) {
        throw StateError('Category not found.');
      }

      final currentBalance = (accountRow['balance'] as num).toDouble();
      final delta = switch (transaction.type) {
        TransactionType.income => transaction.amount,
        TransactionType.expense => -transaction.amount,
      };

      await _updateAccountBalance(
        transactionDb,
        userId: userId,
        accountId: transaction.accountId,
        nextBalance: currentBalance + delta,
      );
    });
  }

  @override
  Future<void> transferBetweenAccounts({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    await _database.transaction((transactionDb) async {
      if (amount <= 0) {
        throw StateError('Transfer amount must be greater than zero.');
      }

      if (fromAccountId == toAccountId) {
        throw StateError('Select two different accounts for the transfer.');
      }

      final fromAccountRow = await _loadAccountRow(
        transactionDb,
        userId: userId,
        accountId: fromAccountId,
      );
      final toAccountRow = await _loadAccountRow(
        transactionDb,
        userId: userId,
        accountId: toAccountId,
      );
      if (fromAccountRow == null || toAccountRow == null) {
        throw StateError('One of the selected accounts no longer exists.');
      }

      final fromCurrency = fromAccountRow['currency_code'] as String;
      final toCurrency = toAccountRow['currency_code'] as String;
      if (fromCurrency != toCurrency) {
        throw StateError(
          'Transfers between different currencies are not available yet.',
        );
      }

      final fromBalance = (fromAccountRow['balance'] as num).toDouble();
      final toBalance = (toAccountRow['balance'] as num).toDouble();
      if (fromBalance < amount) {
        throw StateError('Not enough balance in ${fromAccountRow['name']}.');
      }

      await _updateAccountBalance(
        transactionDb,
        userId: userId,
        accountId: fromAccountId,
        nextBalance: fromBalance - amount,
      );
      await _updateAccountBalance(
        transactionDb,
        userId: userId,
        accountId: toAccountId,
        nextBalance: toBalance + amount,
      );
    });
  }

  @override
  Future<void> addRecurringTemplate({
    required String userId,
    required FinanceTemplate template,
  }) async {
    final sortOrder = await _nextSortOrder(
      _database,
      recurringTemplatesTable,
      userId: userId,
    );
    await _database.insert(
      recurringTemplatesTable,
      _templateToRow(userId, template, sortOrder: sortOrder),
    );
  }

  @override
  Future<void> updateRecurringTemplate({
    required String userId,
    required FinanceTemplate template,
  }) async {
    final updatedCount = await _database.update(
      recurringTemplatesTable,
      _templateToRow(userId, template),
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, template.id],
    );

    if (updatedCount == 0) {
      throw StateError('Template not found.');
    }
  }

  @override
  Future<void> deleteRecurringTemplate({
    required String userId,
    required String templateId,
  }) async {
    await _database.delete(
      recurringTemplatesTable,
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, templateId],
    );
  }

  @override
  Future<void> renameTemplateGroup({
    required String userId,
    required String oldGroupName,
    required String newGroupName,
  }) async {
    if (newGroupName.trim().isEmpty) {
      throw StateError('Group name cannot be empty.');
    }

    await _database.update(
      recurringTemplatesTable,
      <String, Object?>{'group_name': newGroupName.trim()},
      where: 'user_id = ? AND group_name = ?',
      whereArgs: <Object?>[userId, oldGroupName],
    );
  }

  @override
  Future<void> deleteTemplateGroup({
    required String userId,
    required String groupName,
  }) async {
    await _database.delete(
      recurringTemplatesTable,
      where: 'user_id = ? AND group_name = ?',
      whereArgs: <Object?>[userId, groupName],
    );
  }

  @override
  Future<void> addAccount({
    required String userId,
    required FinanceAccount account,
  }) async {
    final sortOrder = await _nextSortOrder(_database, accountsTable, userId: userId);
    await _database.insert(
      accountsTable,
      _accountToRow(userId, account, sortOrder: sortOrder),
    );
  }

  @override
  Future<void> updateAccount({
    required String userId,
    required FinanceAccount account,
  }) async {
    final updatedCount = await _database.update(
      accountsTable,
      _accountToRow(userId, account),
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, account.id],
    );

    if (updatedCount == 0) {
      throw StateError('Account not found.');
    }
  }

  @override
  Future<void> deleteAccount({
    required String userId,
    required String accountId,
  }) async {
    await _database.transaction((transactionDb) async {
      final primaryAccountRows = await transactionDb.query(
        accountsTable,
        columns: <String>['id'],
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
        orderBy: 'sort_order ASC',
        limit: 1,
      );

      if (primaryAccountRows.isEmpty ||
          primaryAccountRows.first['id'] == accountId) {
        throw StateError('The main account cannot be removed.');
      }

      final transactionCount = await _countRows(
        transactionDb,
        transactionsTable,
        userId: userId,
        where: 'account_id = ?',
        whereArgs: <Object?>[accountId],
      );
      if (transactionCount > 0) {
        throw StateError(
          'Move or delete transactions before removing this account.',
        );
      }

      final templateCount = await _countRows(
        transactionDb,
        recurringTemplatesTable,
        userId: userId,
        where: 'account_id = ?',
        whereArgs: <Object?>[accountId],
      );
      if (templateCount > 0) {
        throw StateError(
          'Move or delete templates before removing this account.',
        );
      }

      await transactionDb.delete(
        accountsTable,
        where: 'user_id = ? AND id = ?',
        whereArgs: <Object?>[userId, accountId],
      );
    });
  }

  @override
  Future<void> addCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    final sortOrder = await _nextSortOrder(
      _database,
      categoriesTable,
      userId: userId,
    );
    await _database.insert(
      categoriesTable,
      _categoryToRow(userId, category, sortOrder: sortOrder),
    );
  }

  @override
  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    final updatedCount = await _database.update(
      categoriesTable,
      _categoryToRow(userId, category),
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, category.id],
    );

    if (updatedCount == 0) {
      throw StateError('Category not found.');
    }
  }

  @override
  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    await _database.transaction((transactionDb) async {
      final transactionCount = await _countRows(
        transactionDb,
        transactionsTable,
        userId: userId,
        where: 'category_id = ?',
        whereArgs: <Object?>[categoryId],
      );
      if (transactionCount > 0) {
        throw StateError(
          'Delete or reassign transactions before removing this category.',
        );
      }

      final templateCount = await _countRows(
        transactionDb,
        recurringTemplatesTable,
        userId: userId,
        where: 'category_id = ?',
        whereArgs: <Object?>[categoryId],
      );
      if (templateCount > 0) {
        throw StateError(
          'Delete or reassign templates before removing this category.',
        );
      }

      await transactionDb.delete(
        categoriesTable,
        where: 'user_id = ? AND id = ?',
        whereArgs: <Object?>[userId, categoryId],
      );
    });
  }

  static Map<String, Object?> _accountToRow(
    String userId,
    FinanceAccount account, {
    int? sortOrder,
  }) {
    return <String, Object?>{
      'user_id': userId,
      'id': account.id,
      'name': account.name,
      'account_kind': account.kind.name,
      'balance': account.balance,
      'currency_code': account.currencyCode,
      'accent_color_value': account.accentColorValue,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  static FinanceAccount _accountFromRow(Map<String, Object?> row) {
    return FinanceAccount(
      id: row['id'] as String,
      name: row['name'] as String,
      kind: AccountKind.values.byName(row['account_kind'] as String),
      balance: (row['balance'] as num).toDouble(),
      currencyCode: row['currency_code'] as String,
      accentColorValue: row['accent_color_value'] as int,
    );
  }

  static Map<String, Object?> _categoryToRow(
    String userId,
    FinanceCategory category, {
    int? sortOrder,
  }) {
    return <String, Object?>{
      'user_id': userId,
      'id': category.id,
      'name': category.name,
      'emoji': category.emoji,
      'tone': category.tone.name,
      'category_kind': category.kind.name,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  static FinanceCategory _categoryFromRow(Map<String, Object?> row) {
    return FinanceCategory(
      id: row['id'] as String,
      name: row['name'] as String,
      emoji: row['emoji'] as String,
      tone: CategoryTone.values.byName(row['tone'] as String),
      kind: CategoryKind.values.byName(row['category_kind'] as String),
    );
  }

  static Map<String, Object?> _templateToRow(
    String userId,
    FinanceTemplate template, {
    int? sortOrder,
  }) {
    return <String, Object?>{
      'user_id': userId,
      'id': template.id,
      'title': template.title,
      'amount': template.amount,
      'currency_code': template.currencyCode,
      'account_id': template.accountId,
      'category_id': template.categoryId,
      'group_name': template.groupName,
      'recurrence_interval': template.interval.name,
      'note': template.note,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  static FinanceTemplate _templateFromRow(Map<String, Object?> row) {
    return FinanceTemplate(
      id: row['id'] as String,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      currencyCode: row['currency_code'] as String,
      accountId: row['account_id'] as String,
      categoryId: row['category_id'] as String,
      groupName: row['group_name'] as String,
      interval: RecurrenceInterval.values.byName(
        row['recurrence_interval'] as String,
      ),
      note: row['note'] as String,
    );
  }

  static Map<String, Object?> _transactionToRow(
    String userId,
    FinanceTransaction transaction, {
    int? sortOrder,
  }) {
    return <String, Object?>{
      'user_id': userId,
      'id': transaction.id,
      'title': transaction.title,
      'amount': transaction.amount,
      'currency_code': transaction.currencyCode,
      'transaction_type': transaction.type.name,
      'account_id': transaction.accountId,
      'category_id': transaction.categoryId,
      'occurred_at': transaction.occurredAt.toIso8601String(),
      'note': transaction.note,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  static FinanceTransaction _transactionFromRow(Map<String, Object?> row) {
    return FinanceTransaction(
      id: row['id'] as String,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      currencyCode: row['currency_code'] as String,
      type: TransactionType.values.byName(row['transaction_type'] as String),
      accountId: row['account_id'] as String,
      categoryId: row['category_id'] as String,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      note: row['note'] as String,
    );
  }

  static Future<Map<String, Object?>?> _loadAccountRow(
    DatabaseExecutor database,
    {
    required String userId,
    required String accountId,
  }) async {
    final rows = await database.query(
      accountsTable,
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, accountId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<String> _loadReportingCurrencyCode(String userId) async {
    final rows = await _database.query(
      usersTable,
      columns: <String>['preferred_currency_code'],
      where: 'id = ?',
      whereArgs: <Object?>[userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return exchangeRateBaseCurrencyCode;
    }

    return rows.first['preferred_currency_code'] as String? ??
        exchangeRateBaseCurrencyCode;
  }

  Future<Map<String, double>> _loadExchangeRates() async {
    final rows = await _database.query(exchangeRatesTable);
    return <String, double>{
      for (final row in rows)
        row['currency_code'] as String: (row['rate_to_base'] as num).toDouble(),
    };
  }

  static Future<bool> _rowExists(
    DatabaseExecutor database,
    String table, {
    required String userId,
    required String id,
  }) async {
    final rows = await database.query(
      table,
      columns: <String>['id'],
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<int> _countRows(
    DatabaseExecutor database,
    String table, {
    required String userId,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final effectiveWhere = where == null ? 'user_id = ?' : 'user_id = ? AND $where';
    final effectiveArgs = <Object?>[userId, ...?whereArgs];
    final result = await database.query(
      table,
      columns: <String>['COUNT(*) AS total'],
      where: effectiveWhere,
      whereArgs: effectiveArgs,
    );
    return (result.first['total'] as int?) ?? 0;
  }

  static Future<int> _nextSortOrder(
    DatabaseExecutor database,
    String table, {
    required String userId,
  }) async {
    final result = await database.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_sort_order '
      'FROM $table WHERE user_id = ?',
      <Object?>[userId],
    );
    return (result.first['next_sort_order'] as int?) ?? 0;
  }

  static Future<void> _updateAccountBalance(
    DatabaseExecutor database, {
    required String userId,
    required String accountId,
    required double nextBalance,
  }) async {
    await database.update(
      accountsTable,
      <String, Object?>{'balance': nextBalance},
      where: 'user_id = ? AND id = ?',
      whereArgs: <Object?>[userId, accountId],
    );
  }
}
