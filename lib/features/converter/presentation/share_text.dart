import '../../../core/format/money_format.dart';
import '../../../core/format/clock_time.dart';
import '../providers.dart';

/// Texto que acompaña a la captura del cálculo.
String buildShareText(ConversionView view, {DateTime? now}) {
  final amount = '${MoneyFormat.number(view.amount)} ${view.from.code}';
  final at = view.effectiveAt;
  final age = at == null ? '' : ' · ${clockTime(at, now: now)}';
  final cached = view.stale ? ' · tasa guardada' : '';

  return [
    '$amount = ${view.formattedResult}',
    '${view.formattedRate}$age$cached',
    '',
    'Calculado con Churupos, la calculadora de cambio para Venezuela.',
    'Descarga la app: https://churupos.isdose.com',
  ].join('\n');
}
