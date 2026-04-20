import 'package:flutter/material.dart';

const List<int> kAccountAccentOptions = [
  0xFF58BE83,
  0xFF4F85E8,
  0xFF6264E6,
  0xFF7A57E8,
  0xFFD65298,
  0xFFE45164,
  0xFFF1A533,
  0xFF54BEB0,
];

Color accountAccentColor(int colorValue) => Color(colorValue);

LinearGradient accountCardGradient(int colorValue) {
  final base = accountAccentColor(colorValue);
  final hsl = HSLColor.fromColor(base);

  final start = hsl
      .withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0))
      .toColor();
  final end = hsl
      .withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0))
      .toColor();

  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [start, end],
  );
}
