import 'package:money_trace/core/settings/app_settings_repository.dart';
import 'package:money_trace/core/settings/app_user_settings.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';
import 'package:money_trace/data/local/money_trace_database.dart';
import 'package:sqflite_common/sqlite_api.dart';

class SqliteAppSettingsRepository implements AppSettingsRepository {
  SqliteAppSettingsRepository._(this._database);

  final Database _database;

  static Future<SqliteAppSettingsRepository> open({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) async {
    final database = await openMoneyTraceDatabase(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
    );
    return SqliteAppSettingsRepository._(database);
  }

  Future<void> close() {
    return _database.close();
  }

  @override
  Future<AppUserSettings?> loadSettings(String userId) async {
    final rows = await _database.query(
      userSettingsTable,
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return AppUserSettings(
      themePreset: AppThemePreset.values.byName(row['theme_preset'] as String),
      multiAccountModeEnabled:
          ((row['multi_account_mode_enabled'] as int?) ?? 0) == 1,
    );
  }

  @override
  Future<void> saveSettings({
    required String userId,
    required AppThemePreset themePreset,
    required bool multiAccountModeEnabled,
  }) {
    return _database.insert(
      userSettingsTable,
      <String, Object?>{
        'user_id': userId,
        'theme_preset': themePreset.name,
        'multi_account_mode_enabled': multiAccountModeEnabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
