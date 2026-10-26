import 'package:flutter_test/flutter_test.dart';

import 'package:churupos/core/format/relative_time.dart';

void main() {
  final now = DateTime(2026, 10, 23, 9, 41);

  test('menos de un minuto dice ahora', () {
    expect(
      relativeTime(now.subtract(const Duration(seconds: 30)), now: now),
      'ahora',
    );
  });

  test('minutos', () {
    expect(
      relativeTime(now.subtract(const Duration(minutes: 4)), now: now),
      'hace 4 min',
    );
  });

  test('hoy con hora', () {
    expect(relativeTime(DateTime(2026, 10, 23, 0, 0), now: now), 'hoy 00:00');
  });

  test('ayer con hora', () {
    expect(
      relativeTime(DateTime(2026, 10, 22, 18, 20), now: now),
      'ayer 18:20',
    );
  });

  test('fecha antigua', () {
    expect(relativeTime(DateTime(2026, 10, 19, 7, 5), now: now), '19/10 07:05');
  });

  test('fecha futura no rompe', () {
    expect(
      relativeTime(now.add(const Duration(minutes: 5)), now: now),
      'ahora',
    );
  });
}
