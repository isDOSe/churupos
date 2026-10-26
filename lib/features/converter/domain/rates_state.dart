import 'currency.dart';
import 'rate_error.dart';
import 'rate_quote.dart';

class RatesState {
  const RatesState({
    required this.quotes,
    this.errors = const {},
    this.fetchedAt,
    this.lastAttempt,
    this.refreshing = false,
    this.fromCache = false,
  });

  factory RatesState.empty(DateTime now) =>
      RatesState(quotes: {Currency.ves: RateQuote.baseVes(now)});

  final Map<Currency, RateQuote> quotes;
  final Map<RateSource, RateError> errors;
  final DateTime? fetchedAt;
  final DateTime? lastAttempt;
  final bool refreshing;
  final bool fromCache;

  bool get hasRemoteData => quotes.length > 1;
  bool get isOffline => fromCache;

  bool isAvailable(Currency currency) => quotes.containsKey(currency);

  RateError? errorFor(Currency currency) => switch (currency) {
    Currency.ves => null,
    Currency.usd || Currency.eur => errors[RateSource.dolarApi],
    Currency.usdt => errors[RateSource.binanceP2p],
  };

  RatesState copyWith({
    Map<Currency, RateQuote>? quotes,
    Map<RateSource, RateError>? errors,
    DateTime? fetchedAt,
    DateTime? lastAttempt,
    bool? refreshing,
    bool? fromCache,
  }) {
    return RatesState(
      quotes: quotes ?? this.quotes,
      errors: errors ?? this.errors,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      refreshing: refreshing ?? this.refreshing,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
