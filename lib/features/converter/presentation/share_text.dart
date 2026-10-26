import '../../../core/format/money_format.dart';
import '../providers.dart';

/// Texto que acompaña a la captura del cálculo.
String buildShareText(ConversionView view) {
  final amount = '${MoneyFormat.number(view.amount)} ${view.from.code}';
  final sharedAt = DateTime.now();
  final hh = sharedAt.hour.toString().padLeft(2, '0');
  final mm = sharedAt.minute.toString().padLeft(2, '0');
  final age = ' · hoy $hh:$mm';
  final cached = view.stale ? ' · tasa guardada' : '';

  return [
    '$amount = ${view.formattedResult}',
    '${view.formattedRate}$age$cached',
    '',
    'Calculado con Churupos, la calculadora de cambio para Venezuela.',
    'Descarga la app: https://churupos.isdose.com',
  ].join('\n');
}
