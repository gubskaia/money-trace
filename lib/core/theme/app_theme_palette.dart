import 'package:flutter/material.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';

class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color gradientStart;
  final Color gradientEnd;

  factory AppThemePalette.fromPreset(AppThemePreset preset) {
    return AppThemePalette(
      primary: preset.primary,
      primaryDark: preset.primaryDark,
      primaryLight: preset.primaryLight,
      gradientStart: preset.gradientStart,
      gradientEnd: preset.gradientEnd,
    );
  }

  @override
  ThemeExtension<AppThemePalette> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    return AppThemePalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  ThemeExtension<AppThemePalette> lerp(
    covariant ThemeExtension<AppThemePalette>? other,
    double t,
  ) {
    if (other is! AppThemePalette) {
      return this;
    }

    return AppThemePalette(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t) ?? primaryDark,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t) ??
          primaryLight,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t) ??
          gradientStart,
      gradientEnd:
          Color.lerp(gradientEnd, other.gradientEnd, t) ?? gradientEnd,
    );
  }
}

extension AppThemePaletteX on BuildContext {
  AppThemePalette get appPalette =>
      Theme.of(this).extension<AppThemePalette>()!;
}
