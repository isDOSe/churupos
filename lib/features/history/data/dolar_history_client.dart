import 'package:dio/dio.dart';

import '../../converter/data/network_error.dart';
import '../../converter/domain/currency.dart';
import '../../converter/domain/rate_error.dart';
import '../domain/rate_point.dart';

/// Serie histórica del BCV publicada por dolarapi.com.
///
/// El endpoint no acepta filtros por rango: devuelve toda la serie y aquí se
/// recorta a los últimos [keepDays] días antes de guardarla.
class DolarHistoryClient {
  DolarHistoryClient(this._dio);

  static const String dollarsEndpoint =
      'https://ve.dolarapi.com/v1/historicos/dolares';
  static const String eurosEndpoint =
      'https://ve.dolarapi.com/v1/historicos/euros';
  static const int keepDays = 120;

  final Dio _dio;

  Future<Map<Currency, List<RatePoint>>> fetch({DateTime? now}) async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>(dollarsEndpoint),
        _dio.get<dynamic>(eurosEndpoint),
      ]);

      final series = <Currency, List<RatePoint>>{
        Currency.usd: parseHistory(responses[0].data, now: now),
        Currency.eur: parseHistory(responses[1].data, now: now),
      }..removeWhere((_, points) => points.isEmpty);

      if (series.isEmpty) {
        throw const RateFailure(RateError.unavailable);
      }
      return series;
    } on DioException catch (error) {
      throw RateFailure(mapDioError(error), error.message);
    }
  }
}

/// Convierte la respuesta de dolarapi en puntos diarios del BCV oficial.
///
/// La respuesta mezcla oficial y paralelo; la app usa solo el oficial porque es
/// el que muestra el conversor. Si hay varias filas del mismo día gana la última.
List<RatePoint> parseHistory(
  Object? data, {
  DateTime? now,
  int keepDays = DolarHistoryClient.keepDays,
}) {
  if (data is! List) {
    throw const RateFailure(RateError.badResponse);
  }

  final byDay = <DateTime, RatePoint>{};
  for (final item in data) {
    if (item is! Map) continue;
    if (item['fuente']?.toString() != 'oficial') continue;

    final date = parseDay(item['fecha']?.toString() ?? '');
    final price = (item['promedio'] as num?)?.toDouble();
    if (date == null || price == null || !price.isFinite || price <= 0) {
      continue;
    }
    byDay[date] = RatePoint(date: date, vesPerUnit: price);
  }

  final current = now ?? DateTime.now();
  final end = DateTime(current.year, current.month, current.day);
  final cutoff = end.subtract(Duration(days: keepDays - 1));

  final points =
      byDay.values.where((point) => !point.date.isBefore(cutoff)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  return points;
}
