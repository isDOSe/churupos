import 'package:flutter_test/flutter_test.dart';

import 'package:churupos/features/converter/domain/conversion.dart';
import 'package:churupos/features/converter/domain/currency.dart';
import 'package:churupos/features/converter/domain/rate_quote.dart';

RateQuote quote(Currency currency, double rate) => RateQuote(
  currency: currency,
  vesPerUnit: rate,
  updatedAt: DateTime(2026, 10, 23, 9, 41),
  source: RateSource.dolarApi,
);

void main() {
  final usd = quote(Currency.usd, 886.2271);
  final eur = quote(Currency.eur, 993.08836371);
  final usdt = quote(Currency.usdt, 1000.616);
  final ves = RateQuote.baseVes(DateTime(2026, 10, 23, 9, 41));

  group('convert', () {
    test('30 USD a VES', () {
      expect(convert(30, usd, ves), closeTo(26586.813, 0.0001));
    });

    test('30 EUR a USD', () {
      expect(convert(30, eur, usd), closeTo(33.618, 0.001));
    });

    test('100 VES a USDT', () {
      expect(convert(100, ves, usdt), closeTo(0.099938, 1e-6));
    });

    test('50 USDT a EUR', () {
      expect(convert(50, usdt, eur), closeTo(50.379, 0.001));
    });

    test('identidad sin cambio de valor', () {
      expect(convert(42.5, usd, usd), 42.5);
    });

    test('ida y vuelta vuelve al monto original', () {
      final ida = convert(125.75, usd, eur);
      final vuelta = convert(ida, eur, usd);
      expect(vuelta, closeTo(125.75, 1e-9));
    });

    test('monto cero da cero', () {
      expect(convert(0, usd, ves), 0);
      expect(convert(-5, usd, ves), 0);
    });

    test('montos grandes siguen siendo finitos', () {
      expect(convert(1e9, usd, ves).isFinite, isTrue);
    });

    test('tasas no positivas fallan', () {
      final invalida = quote(Currency.usd, 0);
      expect(() => convert(1, invalida, ves), throwsArgumentError);
      expect(() => crossRate(ves, invalida), throwsArgumentError);
    });
  });

  group('crossRate', () {
    test('1 USD en VES', () {
      expect(crossRate(usd, ves), 886.2271);
    });

    test('1 VES en USD', () {
      expect(crossRate(ves, usd), closeTo(0.001128, 1e-6));
    });
  });
}
