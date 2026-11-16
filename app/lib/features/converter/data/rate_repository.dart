import '../domain/currency.dart';
import '../domain/rate_error.dart';
import '../domain/rate_quote.dart';
import '../domain/rates_state.dart';
import 'binance_p2p_client.dart';
import 'dolar_api_client.dart';
import 'rate_cache.dart';

abstract interface class RatesRepository {
  Future<RatesState> loadCached();

  Future<RatesState> refresh(RatesState previous);
}

class RateRepository implements RatesRepository {
  RateRepository(this._dolar, this._binance, this._cache);

  final DolarApiClient _dolar;
  final BinanceP2pClient _binance;
  final RateCache _cache;

  @override
  Future<RatesState> loadCached() async {
    final cached = _cache.read();
    if (cached == null) return RatesState.empty(DateTime.now());
    return RatesState(
      quotes: cached.quotes,
      fetchedAt: cached.fetchedAt,
      fromCache: true,
    );
  }

  @override
  Future<RatesState> refresh(RatesState previous) async {
    final now = DateTime.now();

    final dolarFuture = _fetchDolar();
    final binanceFuture = _fetchBinance();
    final dolar = await dolarFuture;
    final binance = await binanceFuture;

    final quotes = Map<Currency, RateQuote>.from(previous.quotes);
    quotes.putIfAbsent(Currency.ves, () => RateQuote.baseVes(now));

    final errors = <RateSource, RateError>{};
    var anyFresh = false;

    if (dolar.quotes != null) {
      anyFresh = true;
      for (final quote in dolar.quotes!.values) {
        quotes[quote.currency] = quote;
      }
      for (final currency in const [Currency.usd, Currency.eur]) {
        if (!dolar.quotes!.containsKey(currency)) {
          final cached = quotes[currency];
          if (cached != null) quotes[currency] = cached.copyWith(stale: true);
        }
      }
    } else {
      errors[RateSource.dolarApi] = dolar.error ?? RateError.network;
      for (final currency in const [Currency.usd, Currency.eur]) {
        final cached = quotes[currency];
        if (cached != null) quotes[currency] = cached.copyWith(stale: true);
      }
    }

    if (binance.quote != null) {
      anyFresh = true;
      quotes[Currency.usdt] = binance.quote!;
    } else {
      errors[RateSource.binanceP2p] = binance.error ?? RateError.network;
      final cached = quotes[Currency.usdt];
      if (cached != null) {
        quotes[Currency.usdt] = cached.copyWith(stale: true);
      }
    }

    if (anyFresh) {
      await _cache.write(quotes, now);
    }

    return RatesState(
      quotes: quotes,
      errors: errors,
      fetchedAt: anyFresh ? now : previous.fetchedAt,
      lastAttempt: now,
      fromCache: !anyFresh,
    );
  }

  Future<({Map<Currency, RateQuote>? quotes, RateError? error})>
  _fetchDolar() async {
    try {
      return (quotes: await _dolar.fetch(), error: null);
    } on RateFailure catch (failure) {
      return (quotes: null, error: failure.kind);
    } catch (_) {
      return (quotes: null, error: RateError.network);
    }
  }

  Future<({RateQuote? quote, RateError? error})> _fetchBinance() async {
    try {
      return (quote: await _binance.fetch(), error: null);
    } on RateFailure catch (failure) {
      return (quote: null, error: failure.kind);
    } catch (_) {
      return (quote: null, error: RateError.network);
    }
  }
}
