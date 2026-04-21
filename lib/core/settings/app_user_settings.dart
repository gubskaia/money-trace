import 'package:money_trace/core/theme/app_theme_preset.dart';

class AppUserSettings {
  const AppUserSettings({
    required this.themePreset,
    required this.multiAccountModeEnabled,
  });

  final AppThemePreset themePreset;
  final bool multiAccountModeEnabled;
}
