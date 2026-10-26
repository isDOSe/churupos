import 'package:flutter_test/flutter_test.dart';

import 'package:churupos/features/converter/data/binance_p2p_client.dart';

void main() {
  group('averageTopPrices', () {
    test('promedia diez precios', () {
      final prices = [
        '1008.498',
        '1004.960',
        '1002.000',
        '1001.000',
        '1000.002',
        '1000.000',
        '1000.000',
        '1000.000',
        '999.000',
        '999.000',
      ];
      expect(averageTopPrices(prices), closeTo(1001.446, 1e-9));
    });

    test('solo usa los diez primeros', () {
      final prices = [
        '10',
        '10',
        '10',
        '10',
        '10',
        '10',
        '10',
        '10',
        '10',
        '10',
        '1000',
      ];
      expect(averageTopPrices(prices), 10);
    });

    test('descarta precios inválidos', () {
      final prices = ['100', 'abc', '-5', '0', '200', '300'];
      expect(averageTopPrices(prices), 200);
    });

    test('menos de tres válidos devuelve null', () {
      expect(averageTopPrices(['100', '200']), isNull);
      expect(averageTopPrices(['abc', '-1', '0']), isNull);
      expect(averageTopPrices([]), isNull);
    });

    test('maneja nulos', () {
      expect(averageTopPrices([null, null, '100', '200', '300']), 200);
    });
  });
}
