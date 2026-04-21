import 'package:flutter/material.dart';

enum AppThemePreset {
  emerald(
    label: 'Emerald',
    primary: Color(0xFF58BE83),
    primaryDark: Color(0xFF4AA873),
    primaryLight: Color(0xFF74D79E),
    gradientStart: Color(0xFF53B47B),
    gradientEnd: Color(0xFF69D4A5),
  ),
  indigo(
    label: 'Indigo',
    primary: Color(0xFF6166E8),
    primaryDark: Color(0xFF4F54D6),
    primaryLight: Color(0xFF7F84F5),
    gradientStart: Color(0xFF595FDB),
    gradientEnd: Color(0xFF7A84F5),
  ),
  rose(
    label: 'Rose',
    primary: Color(0xFFE45E73),
    primaryDark: Color(0xFFD24764),
    primaryLight: Color(0xFFF07D8F),
    gradientStart: Color(0xFFD74D65),
    gradientEnd: Color(0xFFF18195),
  ),
  amber(
    label: 'Amber',
    primary: Color(0xFFF0B63C),
    primaryDark: Color(0xFFD79821),
    primaryLight: Color(0xFFF7C95D),
    gradientStart: Color(0xFFDB9F24),
    gradientEnd: Color(0xFFF7C653),
  ),
  cyan(
    label: 'Cyan',
    primary: Color(0xFF52B8D9),
    primaryDark: Color(0xFF399FBE),
    primaryLight: Color(0xFF6CCAE7),
    gradientStart: Color(0xFF439EBC),
    gradientEnd: Color(0xFF67CAE7),
  ),
  violet(
    label: 'Violet',
    primary: Color(0xFF7B55E7),
    primaryDark: Color(0xFF6941D5),
    primaryLight: Color(0xFF9875F3),
    gradientStart: Color(0xFF6D46DA),
    gradientEnd: Color(0xFF9B7BF3),
  );

  const AppThemePreset({
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String label;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color gradientStart;
  final Color gradientEnd;
}
