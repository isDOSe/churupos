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

    // Separa la parte entera de la decimal sin confundir el punto de miles con
    // la coma decimal. La coma siempre es decimal; un punto es decimal solo si
    // el usuario acaba de escribirlo (menos de tres dígitos a su derecha). Los
    // puntos de miles siempre quedan seguidos de tres o más dígitos, así que
    // no se reinterpretan al escribir el siguiente número.
    final decimalAt = _decimalIndex(cleaned);
    var integer = decimalAt == null
        ? cleaned.replaceAll('.', '')
        : cleaned.substring(0, decimalAt).replaceAll('.', '');
    var decimals = decimalAt == null
        ? ''
        : cleaned.substring(decimalAt + 1).replaceAll(RegExp(r'[^0-9]'), '');

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
    if (decimalAt != null) text = '$grouped,$decimals';
    if (text.isEmpty) text = '0';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Índice del separador decimal dentro de [text], o `null` si no hay parte
  /// decimal. Una coma siempre es decimal; un punto es decimal solo si no es un
  /// separador de miles (es decir, si quedan menos de tres dígitos a su derecha).
  static int? _decimalIndex(String text) {
    final comma = text.indexOf(',');
    if (comma != -1) return comma;

    final dot = text.lastIndexOf('.');
    if (dot != -1 && text.length - dot - 1 < 3) return dot;

    return null;
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
