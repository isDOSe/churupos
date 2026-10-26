import 'package:flutter/services.dart';

/// Mantiene el formato venezolano mientras se escribe: miles con punto,
/// decimales con coma, máximo 12 enteros y 2 decimales.
class AmountInputFormatter extends TextInputFormatter {
  static const int maxIntegerDigits = 12;
  static const int maxDecimals = 2;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    var cleaned = raw.replaceAll(RegExp(r'[^0-9,.]'), '');
    if (cleaned.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    cleaned = cleaned.replaceAll('.', ',');
    final parts = cleaned.split(',');

    var integer = parts.first;
    var decimals = parts.length > 1 ? parts.sublist(1).join() : '';

    integer = integer.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (integer.length > maxIntegerDigits) {
      integer = integer.substring(0, maxIntegerDigits);
    }
    if (decimals.length > maxDecimals) {
      decimals = decimals.substring(0, maxDecimals);
    }

    final grouped = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    var text = grouped;
    if (parts.length > 1) text = '$grouped,$decimals';
    if (text.isEmpty) text = '0';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

double parseAmount(String text) {
  final cleaned = text.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0;
}

String normalizeAmount(String text) {
  if (text.trim().isEmpty) return '';
  var fixed = parseAmount(text).toStringAsFixed(2);
  fixed = fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return fixed.replaceAll('.', ',');
}
