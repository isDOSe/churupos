/// Hora del día en formato 12 h (`1:18 p. m.`). Para fechas anteriores agrega
/// el día, así una tasa guardada ayer no parece recién actualizada.
String clockTime(DateTime when, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = when.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final mm = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'p. m.' : 'a. m.';
  final time = '$hour:$mm $suffix';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);

  if (day == today) return time;
  if (today.difference(day).inDays == 1) return 'ayer $time';

  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m $time';
}
