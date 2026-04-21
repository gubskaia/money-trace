import 'package:flutter/services.dart';

class GroupedAmountInputFormatter extends TextInputFormatter {
  const GroupedAmountInputFormatter();

  static final RegExp _allowedCharactersPattern = RegExp(r'^[0-9\s.,]*$');
  static final RegExp _normalizedAmountPattern = RegExp(r'^\d*\.?\d*$');

  static String formatText(String rawValue) {
    final normalized = _normalize(rawValue);
    if (normalized.isEmpty || !_isNormalizedAmount(normalized)) {
      return '';
    }

    return _formatNormalized(normalized);
  }

  static String formatValue(num value) {
    final numericValue = value.toDouble();
    final isWholeNumber = numericValue == numericValue.roundToDouble();
    final rawValue = isWholeNumber
        ? numericValue.toStringAsFixed(0)
        : numericValue
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');

    return formatText(rawValue);
  }

  static double? parse(String rawValue) {
    final normalized = _normalize(rawValue);
    if (normalized.isEmpty || normalized == '.' || !_isNormalizedAmount(normalized)) {
      return null;
    }

    return double.tryParse(normalized);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_allowedCharactersPattern.hasMatch(newValue.text)) {
      return oldValue;
    }

    final normalized = _normalize(newValue.text);
    if (normalized.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (!_isNormalizedAmount(normalized)) {
      return oldValue;
    }

    final formatted = _formatNormalized(normalized);
    final clampedExtentOffset =
        newValue.selection.extentOffset.clamp(0, newValue.text.length).toInt();
    final normalizedBeforeCursor = _normalize(
      newValue.text.substring(0, clampedExtentOffset),
    );
    final targetContentLength =
        normalizedBeforeCursor.startsWith('.')
            ? normalizedBeforeCursor.length + 1
            : normalizedBeforeCursor.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _selectionOffsetForContentLength(formatted, targetContentLength),
      ),
    );
  }

  static String _normalize(String rawValue) {
    return rawValue.replaceAll(' ', '').replaceAll(',', '.');
  }

  static bool _isNormalizedAmount(String normalized) {
    return _normalizedAmountPattern.hasMatch(normalized);
  }

  static String _formatNormalized(String normalized) {
    final endsWithSeparator = normalized.endsWith('.');
    final parts = normalized.split('.');
    var integerPart = parts.first;
    final fractionalPart = parts.length > 1 ? parts[1] : null;

    if (integerPart.isEmpty) {
      integerPart = '0';
    }

    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final groupedIntegerPart = _groupIntegerPart(integerPart);

    if (endsWithSeparator) {
      return '$groupedIntegerPart.';
    }

    if (fractionalPart != null) {
      return '$groupedIntegerPart.$fractionalPart';
    }

    return groupedIntegerPart;
  }

  static String _groupIntegerPart(String digits) {
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      buffer.write(digits[index]);
      final digitsAfterCurrent = digits.length - index - 1;
      if (digitsAfterCurrent > 0 && digitsAfterCurrent % 3 == 0) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  static int _selectionOffsetForContentLength(
    String formatted,
    int contentLength,
  ) {
    if (contentLength <= 0) {
      return 0;
    }

    var seenContentCharacters = 0;
    for (var index = 0; index < formatted.length; index++) {
      final character = formatted[index];
      if (_isContentCharacter(character)) {
        seenContentCharacters++;
      }

      if (seenContentCharacters == contentLength) {
        return index + 1;
      }
    }

    return formatted.length;
  }

  static bool _isContentCharacter(String character) {
    return character == '.' || _isDigit(character);
  }

  static bool _isDigit(String character) {
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }
}
