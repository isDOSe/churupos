import '../../converter/domain/currency.dart';
import '../../converter/domain/rate_error.dart';
import '../domain/rate_point.dart';
import 'dolar_history_client.dart';
import 'history_cache.dart';
import 'usdt_history_store.dart';

class HistorySnapshot {
  const HistorySnapshot({
    required this.series,
    this.fetchedAt,
    this.error,
    this.fromCache = false,
  });

  final Map<Currency, List<RatePoint>> series;
  final DateTime? fetchedAt;
  final RateError? error;
  final bool fromCache;

  List<RatePoint> pointsFor(Currency currency) =>
      series[currency] ?? const <RatePoint>[];
}

class HistoryRepository {
  HistoryRepository(this._client, this._cache, this._usdt);

  /// El BCV publica una vez al día; seis horas evitan descargar la serie en
  /// cada apertura sin arriesgar datos viejos.
  static const Duration maxAge = Duration(hours: 6);

  final DolarHistoryClient _client;
  final HistoryCache _cache;
  final UsdtHistoryStore _usdt;

  /// Guarda el USDT de hoy. Lo llama el refresco de tasas y también la
  /// pantalla de historial al abrirse, para no perder el día.
  Future<void> recordUsdt(double vesPerUnit, DateTime at) =>
      _usdt.record(vesPerUnit, at);

  /// Valor de una fecha concreta. El BCV se consulta en dolarapi; USDT solo
  /// puede salir de los snapshots que guardó la app.
  Future<RatePoint?> fetchForDate(Currency currency, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    if (currency == Currency.usdt) {
      for (final point in _usdt.read()) {
        if (point.isSameDay(day)) return point;
      }
      return null;
    }
    if (currency == Currency.ves) return null;
    return _client.fetchForDate(currency, day);
  }

  Future<HistorySnapshot> loadCached() async {
    final cached = _cache.read();
    final usdt = _usdt.read();
    return HistorySnapshot(
      series: {...?cached?.series, if (usdt.isNotEmpty) Currency.usdt: usdt},
      fetchedAt: cached?.fetchedAt,
      fromCache: cached != null,
    );
  }

  Future<HistorySnapshot> refresh(
    HistorySnapshot previous, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    final cached = _cache.read();

    final fresh =
        cached != null &&
        cached.series.isNotEmpty &&
        now.difference(cached.fetchedAt) < maxAge;
    if (!force && fresh) {
      return _merge(
        series: {...previous.series, ...cached.series},
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }

    try {
      final fetched = await _client.fetch(now: now);
      await _cache.write(fetched, now);
      return _merge(series: fetched, fetchedAt: now);
    } on RateFailure catch (failure) {
      return _merge(
        series: {...previous.series, ...?cached?.series},
        fetchedAt: previous.fetchedAt ?? cached?.fetchedAt,
        error: failure.kind,
        fromCache: true,
      );
    } catch (_) {
      return _merge(
        series: {...previous.series, ...?cached?.series},
        fetchedAt: previous.fetchedAt ?? cached?.fetchedAt,
        error: RateError.network,
        fromCache: true,
      );
    }
  }

  HistorySnapshot _merge({
    required Map<Currency, List<RatePoint>> series,
    DateTime? fetchedAt,
    RateError? error,
    bool fromCache = false,
  }) {
    final usdt = _usdt.read();
    return HistorySnapshot(
      series: {...series, if (usdt.isNotEmpty) Currency.usdt: usdt},
      fetchedAt: fetchedAt,
      error: error,
      fromCache: fromCache,
    );
  }
}
