import 'package:money_trace/data/local/money_trace_database.dart';
import 'package:money_trace/data/local/password_hasher.dart';
import 'package:money_trace/features/auth/domain/models/auth_session.dart';
import 'package:money_trace/features/auth/domain/repositories/auth_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository._(this._database);

  final Database _database;

  static Future<SqliteAuthRepository> open({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) async {
    final database = await openMoneyTraceDatabase(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
    );
    return SqliteAuthRepository._(database);
  }

  Future<void> close() {
    return _database.close();
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final rows = await _database.rawQuery('''
      SELECT
        s.user_id AS user_id,
        u.display_name AS display_name,
        u.email AS email,
        u.preferred_currency_code AS preferred_currency_code
      FROM $appSessionTable s
      INNER JOIN $usersTable u ON u.id = s.user_id
      WHERE s.slot = 1
      LIMIT 1
    ''');

    if (rows.isEmpty) {
      return null;
    }

    return _sessionFromRow(rows.first);
  }

  @override
  Future<bool> emailExists(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final rows = await _database.query(
      usersTable,
      columns: <String>['id'],
      where: 'email = ?',
      whereArgs: <Object?>[normalizedEmail],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final rows = await _database.query(
      usersTable,
      where: 'email = ?',
      whereArgs: <Object?>[normalizedEmail],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Incorrect email or password.');
    }

    final user = rows.first;
    final passwordSalt = user['password_salt'] as String;
    final passwordHash = user['password_hash'] as String;
    final matches = PasswordHasher.verify(
      password: password,
      salt: passwordSalt,
      expectedHash: passwordHash,
    );
    if (!matches) {
      throw StateError('Incorrect email or password.');
    }

    final session = _sessionFromUserRow(user);
    await _persistSession(session.userId);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String preferredCurrencyCode,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (await emailExists(normalizedEmail)) {
      throw StateError('An account with this email already exists.');
    }

    final userId = 'usr-${DateTime.now().microsecondsSinceEpoch}';
    final digest = PasswordHasher.hashPassword(password);
    final session = AuthSession(
      userId: userId,
      displayName: fullName.trim(),
      email: normalizedEmail,
      preferredCurrencyCode: preferredCurrencyCode.trim().toUpperCase(),
    );

    await _database.transaction((transaction) async {
      await transaction.insert(usersTable, <String, Object?>{
        'id': session.userId,
        'display_name': session.displayName,
        'email': session.email,
        'preferred_currency_code': session.preferredCurrencyCode,
        'password_salt': digest.salt,
        'password_hash': digest.hash,
        'created_at': DateTime.now().toIso8601String(),
      });
      await transaction.insert(
        appSessionTable,
        <String, Object?>{
          'slot': 1,
          'user_id': session.userId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return session;
  }

  @override
  Future<void> signOut() async {
    await _database.delete(appSessionTable, where: 'slot = 1');
  }

  Future<void> _persistSession(String userId) {
    return _database.insert(
      appSessionTable,
      <String, Object?>{
        'slot': 1,
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  AuthSession _sessionFromUserRow(Map<String, Object?> row) {
    return AuthSession(
      userId: row['id'] as String,
      displayName: row['display_name'] as String,
      email: row['email'] as String,
      preferredCurrencyCode: row['preferred_currency_code'] as String,
    );
  }

  AuthSession _sessionFromRow(Map<String, Object?> row) {
    return AuthSession(
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String,
      email: row['email'] as String,
      preferredCurrencyCode: row['preferred_currency_code'] as String,
    );
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
