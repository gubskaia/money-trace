import 'package:flutter/material.dart';
import 'package:money_trace/features/finance/domain/models/finance_advice.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF4F8FC);
  static const surface = Color(0xFFFCFEFF);
  static const ink = Color(0xFF162223);
  static const muted = Color(0xFF66798D);
  static const outline = Color(0xFFD9E3EE);
  static const primary = Color(0xFF0E7C66);
  static const secondary = Color(0xFFE0B04F);
  static const income = Color(0xFF1C8B70);
  static const expense = Color(0xFFC65D48);
  static const info = Color(0xFF2E6FA3);
  static const shadow = Color(0x140D1D30);
}

extension CategoryToneX on CategoryTone {
  Color get color {
    switch (this) {
      case CategoryTone.emerald:
        return const Color(0xFF1C8B70);
      case CategoryTone.amber:
        return const Color(0xFFE09B2E);
      case CategoryTone.coral:
        return const Color(0xFFCA6146);
      case CategoryTone.sky:
        return const Color(0xFF4A87C2);
      case CategoryTone.plum:
        return const Color(0xFF8A5BB2);
    }
  }

  Color get softColor => color.withValues(alpha: 0.14);
}

extension AdviceToneX on AdviceTone {
  Color get color {
    switch (this) {
      case AdviceTone.info:
        return AppColors.info;
      case AdviceTone.success:
        return AppColors.income;
      case AdviceTone.warning:
        return AppColors.expense;
    }
  }

  Color get softColor => color.withValues(alpha: 0.12);
}
