import 'history_range.dart';
import 'rate_point.dart';

/// Recorta la serie a los últimos [HistoryRange.days] días calendario,
/// contando el día de hoy.
List<RatePoint> pointsInRange(
  List<RatePoint> points,
  HistoryRange range, {
  DateTime? today,
}) {
  final current = today ?? DateTime.now();
  final end = DateTime(current.year, current.month, current.day);
  final start = end.subtract(Duration(days: range.days - 1));
  return [
    for (final point in points)
      if (!point.date.isBefore(start) && !point.date.isAfter(end)) point,
  ];
}

/// Resumen de una serie ya recortada al rango visible.
class HistoryStats {
  const HistoryStats({
    this.min,
    this.max,
    this.average,
    this.change,
    this.changePercent,
  });

  factory HistoryStats.of(List<RatePoint> points) {
    if (points.isEmpty) return const HistoryStats();

    var min = points.first.vesPerUnit;
    var max = min;
    var sum = 0.0;
    for (final point in points) {
      if (point.vesPerUnit < min) min = point.vesPerUnit;
      if (point.vesPerUnit > max) max = point.vesPerUnit;
      sum += point.vesPerUnit;
    }

    final first = points.first.vesPerUnit;
    final last = points.last.vesPerUnit;
    final change = points.length < 2 ? null : last - first;
    final percent = first > 0 && change != null ? change / first * 100 : null;

    return HistoryStats(
      min: min,
      max: max,
      average: sum / points.length,
      change: change,
      changePercent: percent,
    );
  }

  final double? min;
  final double? max;
  final double? average;
  final double? change;
  final double? changePercent;

  bool get isEmpty => min == null;
}
