import 'rate_quote.dart';

/// Convierte por bolívares: monto × VES/origen ÷ VES/destino.
double convert(double amount, RateQuote from, RateQuote to) {
  if (amount <= 0) return 0;
  if (from.vesPerUnit <= 0 || to.vesPerUnit <= 0) {
    throw ArgumentError('Las tasas deben ser positivas');
  }
  final result = amount * from.vesPerUnit / to.vesPerUnit;
  return result.isFinite ? result : 0;
}

double crossRate(RateQuote from, RateQuote to) {
  if (from.vesPerUnit <= 0 || to.vesPerUnit <= 0) {
    throw ArgumentError('Las tasas deben ser positivas');
  }
  return from.vesPerUnit / to.vesPerUnit;
}
