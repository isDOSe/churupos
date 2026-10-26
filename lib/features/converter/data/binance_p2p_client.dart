import 'package:dio/dio.dart';

import '../domain/currency.dart';
import '../domain/rate_error.dart';
import '../domain/rate_quote.dart';
import 'network_error.dart';

/// Promedio de las 10 mejores ofertas de venta de USDT.
///
/// El parámetro `tradeType: BUY` significa “quiero comprar USDT”: Binance
/// responde con anuncios cuyo `adv.tradeType` es `SELL` (terceros que venden).
double? averageTopPrices(Iterable<Object?> rawPrices) {
  final prices = <double>[];
  for (final raw in rawPrices) {
    final price = double.tryParse(raw?.toString() ?? '');
    if (price == null || !price.isFinite || price <= 0) continue;
    prices.add(price);
    if (prices.length == 10) break;
  }
  if (prices.length < 3) return null;
  return prices.reduce((a, b) => a + b) / prices.length;
}

class BinanceP2pClient {
  BinanceP2pClient(this._dio);

  static const String endpoint =
      'https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search';

  final Dio _dio;

  Future<RateQuote> fetch() async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {
          'page': 1,
          'rows': 10,
          'payTypes': <String>[],
          'asset': 'USDT',
          'fiat': 'VES',
          'tradeType': 'BUY',
        },
      );

      final body = response.data;
      if (body is! Map) {
        throw const RateFailure(RateError.badResponse);
      }
      final data = body['data'];
      if (data is! List) {
        throw const RateFailure(RateError.badResponse);
      }

      final prices = <Object?>[];
      for (final item in data) {
        if (item is! Map) continue;
        final adv = item['adv'];
        if (adv is Map) prices.add(adv['price']);
      }

      final average = averageTopPrices(prices);
      if (average == null) {
        throw const RateFailure(RateError.unavailable);
      }

      return RateQuote(
        currency: Currency.usdt,
        vesPerUnit: average,
        updatedAt: DateTime.now(),
        source: RateSource.binanceP2p,
      );
    } on DioException catch (error) {
      throw RateFailure(mapDioError(error), error.message);
    }
  }
}
