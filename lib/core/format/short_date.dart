const List<String> _monthsShort = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// `27 oct`, sin depender del locale del teléfono.
String shortDate(DateTime date) => '${date.day} ${_monthsShort[date.month - 1]}';

/// `Hoy`, `Ayer` o `27 oct`.
String relativeDay(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return shortDate(day);
}
