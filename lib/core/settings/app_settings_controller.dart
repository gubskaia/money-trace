import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:money_trace/core/settings/app_settings_repository.dart';
import 'package:money_trace/core/settings/app_user_settings.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    required this.repository,
    this.themePreset = AppThemePreset.emerald,
    this.multiAccountModeEnabled = false,
  });

  final AppSettingsRepository repository;

  String? _activeUserId;
  AppThemePreset themePreset;
  bool multiAccountModeEnabled;

  Future<void> loadForUser(String userId) async {
    _activeUserId = userId;
    final storedSettings = await repository.loadSettings(userId);
    final effectiveSettings =
        storedSettings ??
        const AppUserSettings(
          themePreset: AppThemePreset.emerald,
          multiAccountModeEnabled: false,
        );

    themePreset = effectiveSettings.themePreset;
    multiAccountModeEnabled = effectiveSettings.multiAccountModeEnabled;
    notifyListeners();
  }

  void clearSession() {
    _activeUserId = null;
    themePreset = AppThemePreset.emerald;
    multiAccountModeEnabled = false;
    notifyListeners();
  }

  void updateThemePreset(AppThemePreset preset) {
    if (themePreset == preset) {
      return;
    }
    themePreset = preset;
    notifyListeners();
    unawaited(_persist());
  }

  void setMultiAccountMode(bool enabled) {
    if (multiAccountModeEnabled == enabled) {
      return;
    }
    multiAccountModeEnabled = enabled;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final userId = _activeUserId;
    if (userId == null) {
      return;
    }

    await repository.saveSettings(
      userId: userId,
      themePreset: themePreset,
      multiAccountModeEnabled: multiAccountModeEnabled,
    );
  }
}
