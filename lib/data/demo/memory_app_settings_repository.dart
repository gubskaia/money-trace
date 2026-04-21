import 'package:money_trace/core/settings/app_settings_repository.dart';
import 'package:money_trace/core/settings/app_user_settings.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';

class MemoryAppSettingsRepository implements AppSettingsRepository {
  final Map<String, AppUserSettings> _settingsByUser =
      <String, AppUserSettings>{};

  @override
  Future<AppUserSettings?> loadSettings(String userId) async {
    return _settingsByUser[userId];
  }

  @override
  Future<void> saveSettings({
    required String userId,
    required AppThemePreset themePreset,
    required bool multiAccountModeEnabled,
  }) async {
    _settingsByUser[userId] = AppUserSettings(
      themePreset: themePreset,
      multiAccountModeEnabled: multiAccountModeEnabled,
    );
  }
}
