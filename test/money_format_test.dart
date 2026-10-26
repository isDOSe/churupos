import 'package:flutter_test/flutter_test.dart';

import 'package:churupos/core/format/amount_input_formatter.dart';
import 'package:churupos/core/format/money_format.dart';
import 'package:churupos/features/converter/domain/currency.dart';

void main() {
  group('MoneyFormat', () {
    test('bolívares con miles y dos decimales', () {
      expect(
        MoneyFormat.withCurrency(Currency.ves, 26586.813),
        'Bs. 26.586,81',
      );
    });

    test('dólares con símbolo delante', () {
      expect(MoneyFormat.withCurrency(Currency.usd, 30), '\$ 30,00');
    });

    test('euros con símbolo delante', () {
      expect(MoneyFormat.withCurrency(Currency.eur, 30), '€ 30,00');
    });

    test('USDT con código detrás', () {
      expect(MoneyFormat.withCurrency(Currency.usdt, 30), '30,00 USDT');
    });

    test('cero negativo se normaliza', () {
      expect(MoneyFormat.number(-0.0), '0,00');
    });

    test('tasas menores que uno usan cuatro decimales', () {
      expect(MoneyFormat.rate(Currency.usd, 0.001128), '\$ 0,0011');
    });
  });

  group('AmountInputFormatter', () {
    final formatter = AmountInputFormatter();

    TextEditingValue apply(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );

    test('agrupa miles', () {
      expect(apply('1234567').text, '1.234.567');
    });

    test('acepta coma decimal', () {
      expect(apply('1234,5').text, '1.234,5');
    });

    test('convierte punto en coma decimal', () {
      expect(apply('30.5').text, '30,5');
    });

    test('limita a dos decimales', () {
      expect(apply('10,999').text, '10,99');
    });

    test('elimina ceros a la izquierda', () {
      expect(apply('00030').text, '30');
    });

    test('limita a doce enteros', () {
      expect(apply('1234567890123').text, '123.456.789.012');
    });

    test('vacío se mantiene vacío', () {
      expect(apply('').text, '');
    });
  });

  group('parseAmount / normalizeAmount', () {
    test('parsea texto formateado', () {
      expect(parseAmount('26.586,81'), closeTo(26586.81, 1e-9));
    });

    test('normaliza sin separadores de miles', () {
      expect(normalizeAmount('1.234,50'), '1234,5');
    });

    test('normaliza vacío', () {
      expect(normalizeAmount(''), '');
    });
  });
}
