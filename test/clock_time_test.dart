import 'package:flutter_test/flutter_test.dart';

import 'package:churupos/core/format/clock_time.dart';

void main() {
  final now = DateTime(2026, 10, 28, 13, 18);

  test('hoy muestra solo la hora en formato 12 h', () {
    expect(clockTime(DateTime(2026, 10, 28, 0, 5), now: now), '12:05 a. m.');
    expect(clockTime(now, now: now), '1:18 p. m.');
    expect(clockTime(DateTime(2026, 10, 28, 12), now: now), '12:00 p. m.');
  });

  test('ayer agrega el día', () {
    expect(
      clockTime(DateTime(2026, 10, 27, 18, 20), now: now),
      'ayer 6:20 p. m.',
    );
  });

  test('fechas anteriores agregan la fecha', () {
    expect(
      clockTime(DateTime(2026, 10, 19, 7, 5), now: now),
      '19/10 7:05 a. m.',
    );
  });

  test('no rompe con horas futuras', () {
    expect(
      clockTime(now.add(const Duration(minutes: 5)), now: now),
      '1:23 p. m.',
    );
  });
}
