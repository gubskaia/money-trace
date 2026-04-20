import 'package:flutter/foundation.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    this.themePreset = AppThemePreset.emerald,
    this.multiAccountModeEnabled = false,
  });

  AppThemePreset themePreset;
  bool multiAccountModeEnabled;

  void updateThemePreset(AppThemePreset preset) {
    if (themePreset == preset) {
      return;
    }
    themePreset = preset;
    notifyListeners();
  }

  void setMultiAccountMode(bool enabled) {
    if (multiAccountModeEnabled == enabled) {
      return;
    }
    multiAccountModeEnabled = enabled;
    notifyListeners();
  }
}
