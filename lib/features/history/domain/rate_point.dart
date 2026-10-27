/// Un valor de cierre diario: cuántos bolívares vale una unidad de la moneda.
///
/// [date] siempre se normaliza a medianoche local para poder comparar y
/// ordenar por día sin arrastrar la hora.
class RatePoint {
  RatePoint({required DateTime date, required this.vesPerUnit})
    : date = DateTime(date.year, date.month, date.day);

  final DateTime date;
  final double vesPerUnit;

  bool isSameDay(DateTime other) =>
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;

  Map<String, Object?> toJson() => {'fecha': isoDay(date), 'tasa': vesPerUnit};

  static RatePoint? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final date = parseDay(raw['fecha']?.toString() ?? '');
    final rate = (raw['tasa'] as num?)?.toDouble();
    if (date == null || rate == null || !rate.isFinite || rate <= 0) {
      return null;
    }
    return RatePoint(date: date, vesPerUnit: rate);
  }
}

/// Fecha en formato `YYYY-MM-DD`.
String isoDay(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Acepta `YYYY-MM-DD` (lo que devuelve dolarapi) y cualquier ISO 8601.
DateTime? parseDay(String raw) {
  final value = DateTime.tryParse(raw.trim());
  if (value == null) return null;
  return DateTime(value.year, value.month, value.day);
}
