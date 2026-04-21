import 'package:money_trace/data/local/password_hasher.dart';
import 'package:money_trace/features/finance/domain/models/currency_converter.dart';
import 'package:sqflite_common/sqlite_api.dart';

const moneyTraceDatabaseVersion = 4;
const usersTable = 'users';
const appSessionTable = 'app_session';
const userSettingsTable = 'user_settings';
const exchangeRatesTable = 'exchange_rates';
const accountsTable = 'accounts';
const categoriesTable = 'categories';
const recurringTemplatesTable = 'recurring_templates';
const transactionsTable = 'transactions';

Future<Database> openMoneyTraceDatabase({
  required DatabaseFactory databaseFactory,
  required String databasePath,
}) {
  return databaseFactory.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: moneyTraceDatabaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await createMoneyTraceSchema(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await migrateV1ToV2(database);
        }
        if (oldVersion < 3) {
          await createUserSettingsTable(database);
        }
        if (oldVersion < 4) {
          await migrateV3ToV4(database);
        }
      },
    ),
  );
}

Future<void> createMoneyTraceSchema(Database database) async {
  await database.execute('''
    CREATE TABLE $usersTable (
      id TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      preferred_currency_code TEXT NOT NULL,
      password_salt TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  await database.execute('''
    CREATE TABLE $appSessionTable (
      slot INTEGER PRIMARY KEY CHECK(slot = 1),
      user_id TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $usersTable(id) ON DELETE CASCADE
    )
  ''');
  await createUserSettingsTable(database);
  await createExchangeRatesTable(database);
  await database.execute('''
    CREATE TABLE $accountsTable (
      user_id TEXT NOT NULL,
      id TEXT NOT NULL,
      name TEXT NOT NULL,
      account_kind TEXT NOT NULL,
      balance REAL NOT NULL,
      currency_code TEXT NOT NULL,
      accent_color_value INTEGER NOT NULL,
      sort_order INTEGER NOT NULL,
      PRIMARY KEY (user_id, id),
      FOREIGN KEY (user_id) REFERENCES $usersTable(id) ON DELETE CASCADE
    )
  ''');
  await database.execute('''
    CREATE TABLE $categoriesTable (
      user_id TEXT NOT NULL,
      id TEXT NOT NULL,
      name TEXT NOT NULL,
      emoji TEXT NOT NULL,
      tone TEXT NOT NULL,
      category_kind TEXT NOT NULL,
      sort_order INTEGER NOT NULL,
      PRIMARY KEY (user_id, id),
      FOREIGN KEY (user_id) REFERENCES $usersTable(id) ON DELETE CASCADE
    )
  ''');
  await database.execute('''
    CREATE TABLE $recurringTemplatesTable (
      user_id TEXT NOT NULL,
      id TEXT NOT NULL,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      currency_code TEXT NOT NULL,
      account_id TEXT NOT NULL,
      category_id TEXT NOT NULL,
      group_name TEXT NOT NULL,
      recurrence_interval TEXT NOT NULL,
      note TEXT NOT NULL,
      sort_order INTEGER NOT NULL,
      PRIMARY KEY (user_id, id),
      FOREIGN KEY (user_id) REFERENCES $usersTable(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id, account_id) REFERENCES $accountsTable(user_id, id)
        ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (user_id, category_id) REFERENCES $categoriesTable(user_id, id)
        ON DELETE CASCADE ON UPDATE CASCADE
    )
  ''');
  await database.execute('''
    CREATE TABLE $transactionsTable (
      user_id TEXT NOT NULL,
      id TEXT NOT NULL,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      currency_code TEXT NOT NULL,
      transaction_type TEXT NOT NULL,
      account_id TEXT NOT NULL,
      category_id TEXT NOT NULL,
      occurred_at TEXT NOT NULL,
      note TEXT NOT NULL,
      sort_order INTEGER NOT NULL,
      PRIMARY KEY (user_id, id),
      FOREIGN KEY (user_id) REFERENCES $usersTable(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id, account_id) REFERENCES $accountsTable(user_id, id)
        ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (user_id, category_id) REFERENCES $categoriesTable(user_id, id)
        ON DELETE CASCADE ON UPDATE CASCADE
    )
  ''');
  await database.execute(
    'CREATE INDEX idx_accounts_user_sort ON $accountsTable(user_id, sort_order)',
  );
  await database.execute(
    'CREATE INDEX idx_categories_user_sort ON $categoriesTable(user_id, sort_order)',
  );
  await database.execute(
    'CREATE INDEX idx_templates_user_group ON $recurringTemplatesTable(user_id, group_name)',
  );
  await database.execute(
    'CREATE INDEX idx_transactions_user_occurred ON $transactionsTable(user_id, occurred_at)',
  );
  await seedDefaultExchangeRates(database);
}

Future<void> createUserSettingsTable(Database database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS $userSettingsTable (
      user_id TEXT PRIMARY KEY,
      theme_preset TEXT NOT NULL,
      multi_account_mode_enabled INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $usersTable(id) ON DELETE CASCADE
    )
  ''');
}

Future<void> createExchangeRatesTable(Database database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS $exchangeRatesTable (
      currency_code TEXT PRIMARY KEY,
      rate_to_base REAL NOT NULL,
      updated_at TEXT NOT NULL,
      source TEXT NOT NULL
    )
  ''');
}

Future<void> seedDefaultExchangeRates(Database database) async {
  final updatedAt = DateTime.now().toIso8601String();
  for (final entry in defaultExchangeRatesToBase.entries) {
    await database.insert(exchangeRatesTable, <String, Object?>{
      'currency_code': entry.key,
      'rate_to_base': entry.value,
      'updated_at': updatedAt,
      'source': 'seeded-demo',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

Future<void> migrateV1ToV2(Database database) async {
  const migratedUserId = 'usr-migrated-local';
  final digest = PasswordHasher.hashPassword('1234');
  final legacyCurrency = await _lookupLegacyCurrency(database);

  await database.execute('ALTER TABLE $accountsTable RENAME TO accounts_v1');
  await database.execute('ALTER TABLE $categoriesTable RENAME TO categories_v1');
  await database.execute(
    'ALTER TABLE $recurringTemplatesTable RENAME TO recurring_templates_v1',
  );
  await database.execute(
    'ALTER TABLE $transactionsTable RENAME TO transactions_v1',
  );

  await createMoneyTraceSchema(database);

  await database.insert(usersTable, <String, Object?>{
    'id': migratedUserId,
    'display_name': 'Alex Kowalski',
    'email': 'alex@moneytrace.app',
    'preferred_currency_code': legacyCurrency,
    'password_salt': digest.salt,
    'password_hash': digest.hash,
    'created_at': DateTime.now().toIso8601String(),
  });
  await database.insert(appSessionTable, <String, Object?>{
    'slot': 1,
    'user_id': migratedUserId,
    'updated_at': DateTime.now().toIso8601String(),
  });

  await database.execute('''
    INSERT INTO $accountsTable (
      user_id, id, name, account_kind, balance, currency_code,
      accent_color_value, sort_order
    )
    SELECT
      '$migratedUserId', id, name, account_kind, balance, currency_code,
      accent_color_value, sort_order
    FROM accounts_v1
  ''');
  await database.execute('''
    INSERT INTO $categoriesTable (
      user_id, id, name, emoji, tone, category_kind, sort_order
    )
    SELECT
      '$migratedUserId', id, name, emoji, tone, category_kind, sort_order
    FROM categories_v1
  ''');
  await database.execute('''
    INSERT INTO $recurringTemplatesTable (
      user_id, id, title, amount, currency_code, account_id, category_id, group_name,
      recurrence_interval, note, sort_order
    )
    SELECT
      '$migratedUserId', recurring_templates_v1.id, recurring_templates_v1.title,
      recurring_templates_v1.amount,
      COALESCE(accounts_v1.currency_code, '$exchangeRateBaseCurrencyCode'),
      recurring_templates_v1.account_id, recurring_templates_v1.category_id,
      recurring_templates_v1.group_name, recurring_templates_v1.recurrence_interval,
      recurring_templates_v1.note, recurring_templates_v1.sort_order
    FROM recurring_templates_v1
    LEFT JOIN accounts_v1 ON accounts_v1.id = recurring_templates_v1.account_id
  ''');
  await database.execute('''
    INSERT INTO $transactionsTable (
      user_id, id, title, amount, currency_code, transaction_type, account_id, category_id,
      occurred_at, note, sort_order
    )
    SELECT
      '$migratedUserId', transactions_v1.id, transactions_v1.title,
      transactions_v1.amount,
      COALESCE(accounts_v1.currency_code, '$exchangeRateBaseCurrencyCode'),
      transactions_v1.transaction_type, transactions_v1.account_id,
      transactions_v1.category_id, transactions_v1.occurred_at,
      transactions_v1.note, transactions_v1.sort_order
    FROM transactions_v1
    LEFT JOIN accounts_v1 ON accounts_v1.id = transactions_v1.account_id
  ''');

  await database.execute('DROP TABLE accounts_v1');
  await database.execute('DROP TABLE categories_v1');
  await database.execute('DROP TABLE recurring_templates_v1');
  await database.execute('DROP TABLE transactions_v1');
}

Future<void> migrateV3ToV4(Database database) async {
  await createExchangeRatesTable(database);
  await seedDefaultExchangeRates(database);

  await _addColumnIfMissing(
    database,
    table: recurringTemplatesTable,
    columnName: 'currency_code',
    definition:
        "TEXT NOT NULL DEFAULT '$exchangeRateBaseCurrencyCode'",
  );
  await _addColumnIfMissing(
    database,
    table: transactionsTable,
    columnName: 'currency_code',
    definition:
        "TEXT NOT NULL DEFAULT '$exchangeRateBaseCurrencyCode'",
  );

  await database.execute('''
    UPDATE $recurringTemplatesTable
    SET currency_code = COALESCE(
      (
        SELECT $accountsTable.currency_code
        FROM $accountsTable
        WHERE $accountsTable.user_id = $recurringTemplatesTable.user_id
          AND $accountsTable.id = $recurringTemplatesTable.account_id
      ),
      currency_code,
      '$exchangeRateBaseCurrencyCode'
    )
  ''');

  await database.execute('''
    UPDATE $transactionsTable
    SET currency_code = COALESCE(
      (
        SELECT $accountsTable.currency_code
        FROM $accountsTable
        WHERE $accountsTable.user_id = $transactionsTable.user_id
          AND $accountsTable.id = $transactionsTable.account_id
      ),
      currency_code,
      '$exchangeRateBaseCurrencyCode'
    )
  ''');
}

Future<String> _lookupLegacyCurrency(Database database) async {
  final rows = await database.query(
    accountsTable,
    columns: <String>['currency_code'],
    orderBy: 'sort_order ASC',
    limit: 1,
  );
  if (rows.isEmpty) {
    return 'KZT';
  }

  return rows.first['currency_code'] as String? ?? 'KZT';
}

Future<void> _addColumnIfMissing(
  Database database, {
  required String table,
  required String columnName,
  required String definition,
}) async {
  final tableInfo = await database.rawQuery('PRAGMA table_info($table)');
  final hasColumn = tableInfo.any((row) => row['name'] == columnName);
  if (hasColumn) {
    return;
  }

  await database.execute(
    'ALTER TABLE $table ADD COLUMN $columnName $definition',
  );
}
