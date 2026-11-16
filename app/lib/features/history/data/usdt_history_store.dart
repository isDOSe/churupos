import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rate_point.dart';

/// Historial de USDT construido por la app: Binance P2P no publica precios
/// históricos, así que se guarda un valor por día en cada actualización.
class UsdtHistoryStore {
  UsdtHistoryStore(this._prefs);

  static const String key = 'usdt_history_v1';
  static const int keepDays = 120;

  final SharedPreferences _prefs;

  List<RatePoint> read() {
    final raw = _prefs.getStringList(key);
    if (raw == null) return [];
    final points = [
      for (final value in raw) _decode(value),
    ].whereType<RatePoint>().toList()..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Guarda el valor de [at], reemplazando el del mismo día si ya existía.
  Future<void> record(double vesPerUnit, DateTime at) async {
    if (!vesPerUnit.isFinite || vesPerUnit <= 0) return;

    final points = read();
    final day = DateTime(at.year, at.month, at.day);
    points.removeWhere((point) => point.isSameDay(day));
    points.add(RatePoint(date: day, vesPerUnit: vesPerUnit));
    points.sort((a, b) => a.date.compareTo(b.date));

    final cutoff = day.subtract(const Duration(days: keepDays - 1));
    final kept = [
      for (final point in points)
        if (!point.date.isBefore(cutoff)) point,
    ];

    await _prefs.setStringList(key, [for (final point in kept) _encode(point)]);
  }

  static String _encode(RatePoint point) =>
      '${isoDay(point.date)}|${point.vesPerUnit}';

  static RatePoint? _decode(String value) {
    final separator = value.indexOf('|');
    if (separator <= 0) return null;
    final date = parseDay(value.substring(0, separator));
    final rate = double.tryParse(value.substring(separator + 1));
    if (date == null || rate == null || !rate.isFinite || rate <= 0) {
      return null;
    }
    return RatePoint(date: date, vesPerUnit: rate);
  }
}
