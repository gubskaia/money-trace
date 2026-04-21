import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/data/local/sqlite_auth_repository.dart';
import 'package:money_trace/data/local/sqlite_money_trace_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  test('registers a local user, restores session, and signs in again', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'money_trace_auth_test_',
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
    final financeRepository = await SqliteMoneyTraceRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final session = await authRepository.register(
      fullName: 'Elisei Dev',
      email: 'elisei@example.com',
      password: '1234',
      preferredCurrencyCode: 'USD',
    );
    await financeRepository.bootstrapUserWorkspace(
      userId: session.userId,
      accountName: 'Main Wallet',
      openingBalance: 320,
      currencyCode: 'USD',
    );

    await authRepository.close();
    await financeRepository.close();

    final reopenedAuthRepository = await SqliteAuthRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    final reopenedFinanceRepository = await SqliteMoneyTraceRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final restoredSession = await reopenedAuthRepository.restoreSession();
    final restoredSnapshot = await reopenedFinanceRepository.loadSnapshot(
      userId: session.userId,
    );

    expect(restoredSession, isNotNull);
    expect(restoredSession!.userId, session.userId);
    expect(restoredSession.email, 'elisei@example.com');
    expect(restoredSnapshot.accounts.single.name, 'Main Wallet');
    expect(restoredSnapshot.accounts.single.balance, 320);

    await reopenedAuthRepository.signOut();
    final signedOutSession = await reopenedAuthRepository.restoreSession();
    expect(signedOutSession, isNull);

    final signedInSession = await reopenedAuthRepository.signIn(
      email: 'elisei@example.com',
      password: '1234',
    );
    expect(signedInSession.userId, session.userId);

    await reopenedAuthRepository.close();
    await reopenedFinanceRepository.close();
  });
}
