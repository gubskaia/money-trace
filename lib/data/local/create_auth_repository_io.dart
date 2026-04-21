import 'dart:io';

import 'package:money_trace/data/local/sqlite_auth_repository.dart';
import 'package:money_trace/features/auth/domain/repositories/auth_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AuthRepository> createAuthRepository() async {
  final databaseFactory = _resolveDatabaseFactory();
  final supportDirectory = await getApplicationSupportDirectory();
  await supportDirectory.create(recursive: true);

  final databasePath = p.join(supportDirectory.path, 'money_trace.db');
  return SqliteAuthRepository.open(
    databaseFactory: databaseFactory,
    databasePath: databasePath,
  );
}

DatabaseFactory _resolveDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  return sqflite.databaseFactory;
}
