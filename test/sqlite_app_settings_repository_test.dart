import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';
import 'package:money_trace/data/local/sqlite_app_settings_repository.dart';
import 'package:money_trace/data/local/sqlite_auth_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  test('persists theme and multi-account mode for a user', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'money_trace_settings_test_',
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
    final settingsRepository = await SqliteAppSettingsRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );

    final session = await authRepository.register(
      fullName: 'Settings User',
      email: 'settings@test.dev',
      password: '1234',
      preferredCurrencyCode: 'USD',
    );

    await settingsRepository.saveSettings(
      userId: session.userId,
      themePreset: AppThemePreset.cyan,
      multiAccountModeEnabled: true,
    );
    await authRepository.close();
    await settingsRepository.close();

    final reopenedRepository = await SqliteAppSettingsRepository.open(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    final restoredSettings = await reopenedRepository.loadSettings(session.userId);

    expect(restoredSettings, isNotNull);
    expect(restoredSettings!.themePreset, AppThemePreset.cyan);
    expect(restoredSettings.multiAccountModeEnabled, isTrue);

    await reopenedRepository.close();
  });
}
