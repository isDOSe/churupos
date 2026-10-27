enum HistoryRange {
  week(days: 7, label: '7 días', shortLabel: '7D'),
  month(days: 30, label: '30 días', shortLabel: '30D'),
  quarter(days: 90, label: '90 días', shortLabel: '90D');

  const HistoryRange({
    required this.days,
    required this.label,
    required this.shortLabel,
  });

  final int days;
  final String label;
  final String shortLabel;
}
