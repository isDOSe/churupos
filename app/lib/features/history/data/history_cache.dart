import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../converter/domain/currency.dart';
import '../domain/rate_point.dart';

/// Serie diaria del BCV descargada de dolarapi, guardada para no repetir la
/// descarga en cada apertura de la hoja de historial.
class HistoryCache {
  HistoryCache(this._prefs);

  static const String key = 'rates_history_v1';

  final SharedPreferences _prefs;

  ({Map<Currency, List<RatePoint>> series, DateTime fetchedAt})? read() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;

      final fetchedAt = DateTime.tryParse(json['fetchedAt']?.toString() ?? '');
      final seriesJson = json['series'];
      if (fetchedAt == null || seriesJson is! Map) return null;

      final series = <Currency, List<RatePoint>>{};
      for (final entry in seriesJson.entries) {
        final currency = Currency.fromCode(entry.key.toString());
        if (currency == null ||
            currency == Currency.ves ||
            currency == Currency.usdt) {
          continue;
        }
        final list = entry.value;
        if (list is! List) continue;

        final points =
            [for (final rawPoint in list) RatePoint.fromJson(rawPoint)]
                .whereType<RatePoint>()
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
        if (points.isNotEmpty) series[currency] = points;
      }

      if (series.isEmpty) return null;
      return (series: series, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    Map<Currency, List<RatePoint>> series,
    DateTime fetchedAt,
  ) {
    final payload = <String, Object?>{
      'fetchedAt': fetchedAt.toIso8601String(),
      'series': {
        for (final entry in series.entries)
          if (entry.key == Currency.usd || entry.key == Currency.eur)
            entry.key.code.toLowerCase(): [
              for (final point in entry.value) point.toJson(),
            ],
      },
    };
    return _prefs.setString(key, jsonEncode(payload));
  }
}
