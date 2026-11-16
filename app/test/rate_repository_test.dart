import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:churupos/features/converter/data/binance_p2p_client.dart';
import 'package:churupos/features/converter/data/dolar_api_client.dart';
import 'package:churupos/features/converter/data/rate_cache.dart';
import 'package:churupos/features/converter/data/rate_repository.dart';
import 'package:churupos/features/converter/domain/currency.dart';
import 'package:churupos/features/converter/domain/rate_error.dart';
import 'package:churupos/features/converter/domain/rate_quote.dart';
import 'package:churupos/features/converter/domain/rates_state.dart';

class _FakeDolar extends DolarApiClient {
  _FakeDolar({this.result, this.error}) : super(Dio());

  final Map<Currency, RateQuote>? result;
  final RateError? error;

  @override
  Future<Map<Currency, RateQuote>> fetch() async {
    if (error != null) throw RateFailure(error!);
    return result ?? <Currency, RateQuote>{};
  }
}

class _FakeBinance extends BinanceP2pClient {
  _FakeBinance({this.result, this.error}) : super(Dio());

  final RateQuote? result;
  final RateError? error;

  @override
  Future<RateQuote> fetch() async {
    if (error != null) throw RateFailure(error!);
    return result!;
  }
}

RateQuote quote(Currency currency, double rate, {bool stale = false}) {
  return RateQuote(
    currency: currency,
    vesPerUnit: rate,
    updatedAt: DateTime(2026, 10, 23, 0),
    source: currency == Currency.usdt
        ? RateSource.binanceP2p
        : RateSource.dolarApi,
    stale: stale,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  final now = DateTime(2026, 10, 23, 9, 41);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  RateRepository buildRepository({
    required DolarApiClient dolar,
    required BinanceP2pClient binance,
  }) => RateRepository(dolar, binance, RateCache(prefs));

  RatesState previousWith({bool stale = false}) => RatesState(
    quotes: {
      Currency.ves: RateQuote.baseVes(now),
      Currency.usd: quote(Currency.usd, 886.2271, stale: stale),
      Currency.eur: quote(Currency.eur, 993.08836371, stale: stale),
      Currency.usdt: quote(Currency.usdt, 1000.616, stale: stale),
    },
    fetchedAt: now,
  );

  test('ambas fuentes ok dejan tasas frescas y escriben caché', () async {
    final repository = buildRepository(
      dolar: _FakeDolar(
        result: {
          Currency.usd: quote(Currency.usd, 886.2271),
          Currency.eur: quote(Currency.eur, 993.08836371),
        },
      ),
      binance: _FakeBinance(result: quote(Currency.usdt, 1000.616)),
    );

    final state = await repository.refresh(RatesState.empty(now));

    expect(state.errors, isEmpty);
    expect(state.fromCache, isFalse);
    expect(state.quotes[Currency.usd]!.stale, isFalse);
    expect(state.quotes[Currency.usdt]!.vesPerUnit, closeTo(1000.616, 1e-9));

    final cached = await repository.loadCached();
    expect(cached.quotes[Currency.usd]!.stale, isTrue);
    expect(cached.fromCache, isTrue);
  });

  test('si dolar falla, conserva el valor previo marcado como stale', () async {
    final repository = buildRepository(
      dolar: _FakeDolar(error: RateError.network),
      binance: _FakeBinance(result: quote(Currency.usdt, 1010)),
    );

    final state = await repository.refresh(previousWith());

    expect(state.errors[RateSource.dolarApi], RateError.network);
    expect(state.quotes[Currency.usd]!.vesPerUnit, 886.2271);
    expect(state.quotes[Currency.usd]!.stale, isTrue);
    expect(state.quotes[Currency.usdt]!.stale, isFalse);
    expect(state.fromCache, isFalse);
  });

  test('si ambas fallan sin datos previos, queda sin datos remotos', () async {
    final repository = buildRepository(
      dolar: _FakeDolar(error: RateError.timeout),
      binance: _FakeBinance(error: RateError.unavailable),
    );

    final state = await repository.refresh(RatesState.empty(now));

    expect(state.hasRemoteData, isFalse);
    expect(state.fromCache, isTrue);
    expect(state.errors[RateSource.dolarApi], RateError.timeout);
    expect(state.errors[RateSource.binanceP2p], RateError.unavailable);
  });

  test('si ambas fallan con caché, conserva todo y marca stale', () async {
    final repository = buildRepository(
      dolar: _FakeDolar(error: RateError.network),
      binance: _FakeBinance(error: RateError.network),
    );

    final state = await repository.refresh(previousWith(stale: true));

    expect(state.quotes[Currency.usd]!.vesPerUnit, 886.2271);
    expect(state.quotes[Currency.usdt]!.vesPerUnit, 1000.616);
    expect(
      state.quotes.values
          .where((q) => !q.currency.isBase)
          .every((q) => q.stale),
      isTrue,
    );
    expect(state.fromCache, isTrue);
  });

  test('caché corrupta se ignora', () async {
    await prefs.setString(RateCache.key, 'esto no es json');
    final repository = buildRepository(
      dolar: _FakeDolar(error: RateError.network),
      binance: _FakeBinance(error: RateError.network),
    );

    final state = await repository.loadCached();
    expect(state.hasRemoteData, isFalse);
    expect(state.quotes.keys, [Currency.ves]);
  });
}
