import 'package:flutter_test/flutter_test.dart';

import 'package:churupos/features/converter/domain/currency.dart';
import 'package:churupos/features/converter/providers.dart';
import 'package:churupos/features/converter/presentation/share_text.dart';

ConversionView view({
  double amount = 30,
  double result = 26586.813,
  double rate = 886.2271,
  bool stale = false,
}) {
  return ConversionView(
    from: Currency.usd,
    to: Currency.ves,
    amount: amount,
    result: result,
    unitRate: rate,
    effectiveAt: DateTime(2026, 10, 23, 0),
    available: true,
    stale: stale,
    isEmpty: amount == 0,
  );
}

void main() {
  test('incluye el cálculo, la tasa y la invitación a descargar', () {
    final text = buildShareText(view());

    expect(text, contains('30,00 USD = Bs. 26.586,81'));
    expect(text, contains('1 USD = Bs. 886,23'));
    expect(text, contains('Calculado con Churupos'));
    expect(text, contains('Descarga la app: https://churupos.isdose.com'));
  });

  test('marca las tasas guardadas', () {
    final text = buildShareText(view(stale: true));
    expect(text, contains('tasa guardada'));
  });

  test('no deja líneas vacías al final', () {
    final text = buildShareText(view());
    expect(text.endsWith('https://churupos.isdose.com'), isTrue);
  });
}
