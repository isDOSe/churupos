import 'package:dio/dio.dart';

import '../domain/currency.dart';
import '../domain/rate_error.dart';
import '../domain/rate_quote.dart';
import 'network_error.dart';

class DolarApiClient {
  DolarApiClient(this._dio);

  static const String endpoint = 'https://ve.dolarapi.com/v1/cotizaciones';

  final Dio _dio;

  Future<Map<Currency, RateQuote>> fetch() async {
    try {
      final response = await _dio.get<dynamic>(endpoint);
      final data = response.data;
      if (data is! List) {
        throw const RateFailure(RateError.badResponse);
      }

      final now = DateTime.now();
      final quotes = <Currency, RateQuote>{};

      for (final item in data) {
        if (item is! Map) continue;

        final currency = switch (item['moneda']?.toString().toUpperCase()) {
          'USD' => Currency.usd,
          'EUR' => Currency.eur,
          _ => null,
        };
        if (currency == null) continue;

        final price = (item['promedio'] as num?)?.toDouble();
        if (price == null || !price.isFinite || price <= 0) continue;

        final updatedAt =
            DateTime.tryParse(item['fechaActualizacion']?.toString() ?? '') ??
            now;

        quotes[currency] = RateQuote(
          currency: currency,
          vesPerUnit: price,
          updatedAt: updatedAt,
          source: RateSource.dolarApi,
        );
      }

      if (quotes.isEmpty) {
        throw const RateFailure(RateError.unavailable);
      }
      return quotes;
    } on DioException catch (error) {
      throw RateFailure(mapDioError(error), error.message);
    }
  }
}
