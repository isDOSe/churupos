import 'package:intl/intl.dart';

import '../../features/converter/domain/currency.dart';

/// Formato monetario venezolano, independiente del locale del teléfono.
abstract final class MoneyFormat {
  static final NumberFormat _money = NumberFormat('#,##0.00', 'es_VE');
  static final NumberFormat _rate = NumberFormat('#,##0.00', 'es_VE');
  static final NumberFormat _smallRate = NumberFormat('#,##0.0000', 'es_VE');

  static double _clean(double value) => value.abs() < 5e-10 ? 0 : value;

  static String number(double value) => _money.format(_clean(value));

  static String withCurrency(Currency currency, double value) =>
      _wrap(currency, number(value));

  static String rate(Currency currency, double value) {
    final format = value.abs() < 1 ? _smallRate : _rate;
    return _wrap(currency, format.format(_clean(value)));
  }

  static String _wrap(Currency currency, String number) => switch (currency) {
    Currency.usd => '\$ $number',
    Currency.eur => '€ $number',
    Currency.ves => 'Bs. $number',
    Currency.usdt => '$number USDT',
  };
}
