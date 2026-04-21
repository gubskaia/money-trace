import 'package:money_trace/core/settings/app_user_settings.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';

abstract interface class AppSettingsRepository {
  Future<AppUserSettings?> loadSettings(String userId);

  Future<void> saveSettings({
    required String userId,
    required AppThemePreset themePreset,
    required bool multiAccountModeEnabled,
  });
}
