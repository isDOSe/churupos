String relativeTime(DateTime when, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = when.toLocal();
  final diff = current.difference(local);

  if (diff.inSeconds < 60) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');

  if (day == today) return 'hoy $hh:$mm';
  if (today.difference(day).inDays == 1) return 'ayer $hh:$mm';

  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m $hh:$mm';
}
