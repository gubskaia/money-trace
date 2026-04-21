import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';

abstract final class AppTheme {
  static ThemeData light({required AppThemePreset preset}) {
    final palette = AppThemePalette.fromPreset(preset);
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: AppColors.ink,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: AppColors.ink,
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: AppColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.ink,
      error: AppColors.expense,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.canvas,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.outline,
      outlineVariant: AppColors.outline.withValues(alpha: 0.6),
      shadow: AppColors.shadow,
      scrim: AppColors.ink.withValues(alpha: 0.3),
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      extensions: [palette],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: palette.primary.withValues(alpha: 0.12),
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium ?? const TextStyle();
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return base.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: palette.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.muted, size: 22);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: palette.primary.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        hintStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.primary, width: 1.3),
        ),
      ),
      dividerColor: AppColors.outline.withValues(alpha: 0.6),
    );
  }
}
