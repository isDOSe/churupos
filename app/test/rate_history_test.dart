import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:churupos/features/converter/domain/currency.dart';
import 'package:churupos/features/converter/domain/rate_error.dart';
import 'package:churupos/features/history/data/dolar_history_client.dart';
import 'package:churupos/features/history/data/history_cache.dart';
import 'package:churupos/features/history/data/history_repository.dart';
import 'package:churupos/features/history/data/usdt_history_store.dart';
import 'package:churupos/features/history/domain/history_range.dart';
import 'package:churupos/features/history/domain/rate_history.dart';
import 'package:churupos/features/history/domain/rate_point.dart';

class _FakeClient extends DolarHistoryClient {
  _FakeClient({
    this.result,
    this.error,
    this.datePoint,
  }) : super(Dio());

  final Map<Currency, List<RatePoint>>? result;
  final RateError? error;
  final RatePoint? datePoint;
  int calls = 0;
  DateTime? lastDateRequested;

  @override
  Future<Map<Currency, List<RatePoint>>> fetch({DateTime? now}) async {
    calls++;
    if (error != null) throw RateFailure(error!);
    return result ?? <Currency, List<RatePoint>>{};
  }

  @override
  Future<RatePoint?> fetchForDate(Currency currency, DateTime date) async {
    lastDateRequested = date;
    return datePoint;
  }
}

List<RatePoint> daily(DateTime end, int days, {double start = 100}) {
  return [
    for (var i = days - 1; i >= 0; i--)
      RatePoint(
        date: end.subtract(Duration(days: i)),
        vesPerUnit: start + (days - 1 - i),
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseHistory', () {
    final now = DateTime(2026, 10, 27);

    test('usa solo el BCV oficial, ordena y descarta filas inválidas', () {
      final points = parseHistory([
        {'fuente': 'oficial', 'fecha': '2026-10-26', 'promedio': 886.0},
        {'fuente': 'paralelo', 'fecha': '2026-10-26', 'promedio': 999.0},
        {'fuente': 'oficial', 'fecha': '2026-10-25', 'promedio': 880.0},
        {'fuente': 'oficial', 'fecha': '2026-10-26', 'promedio': 887.0},
        {'fuente': 'oficial', 'fecha': '2026-10-27', 'promedio': 0},
        {'fuente': 'oficial', 'fecha': 'no-es-fecha', 'promedio': 12},
        'basura',
      ], now: now);

      expect(points.map((point) => point.vesPerUnit), [880.0, 887.0]);
      expect(points.last.date, DateTime(2026, 10, 26));
    });

    test('recorta la serie a los últimos días pedidos', () {
      final points = parseHistory(
        [
          {'fuente': 'oficial', 'fecha': '2026-09-27', 'promedio': 800.0},
          {'fuente': 'oficial', 'fecha': '2026-09-28', 'promedio': 801.0},
          {'fuente': 'oficial', 'fecha': '2026-10-27', 'promedio': 887.0},
        ],
        now: now,
        keepDays: 30,
      );

      expect(points.length, 2);
      expect(points.first.vesPerUnit, 801.0);
    });

    test('una respuesta que no es lista falla', () {
      expect(
        () => parseHistory({'detalle': 'error'}),
        throwsA(
          isA<RateFailure>().having(
            (failure) => failure.kind,
            'kind',
            RateError.badResponse,
          ),
        ),
      );
    });
  });

  group('parseDayRate', () {
    test('elige el BCV oficial e ignora el paralelo', () {
      final point = parseDayRate([
        {'fuente': 'paralelo', 'fecha': '2026-10-23', 'promedio': 999.0},
        {'fuente': 'oficial', 'fecha': '2026-10-23', 'promedio': 886.2},
      ]);

      expect(point, isNotNull);
      expect(point!.date, DateTime(2026, 10, 23));
      expect(point.vesPerUnit, 886.2);
    });

    test('sin fila oficial o sin datos devuelve null', () {
      expect(
        parseDayRate([
          {'fuente': 'paralelo', 'fecha': '2026-10-24', 'promedio': 1005.0},
        ]),
        isNull,
      );
      expect(parseDayRate(const []), isNull);
    });

    test('usa la fecha pedida si la respuesta no la incluye', () {
      final requested = DateTime(2025, 1, 2);
      final point = parseDayRate({
        'fuente': 'oficial',
        'promedio': 52.0,
      }, requested: requested);

      expect(point, isNotNull);
      expect(point!.date, requested);
    });

    test('una respuesta que no es lista ni objeto falla', () {
      expect(
        () => parseDayRate('no-es-json'),
        throwsA(
          isA<RateFailure>().having(
            (failure) => failure.kind,
            'kind',
            RateError.badResponse,
          ),
        ),
      );
    });
  });

  group('rango y estadísticas', () {
    final today = DateTime(2026, 10, 27);
    final series = daily(today, 40);

    test('30 días incluye hoy y los 29 anteriores', () {
      final points = pointsInRange(series, HistoryRange.month, today: today);
      expect(points.length, 30);
      expect(points.first.date, DateTime(2026, 9, 28));
      expect(points.last.date, today);
    });

    test('7 días y 90 días respetan el rango', () {
      expect(pointsInRange(series, HistoryRange.week, today: today).length, 7);
      expect(
        pointsInRange(series, HistoryRange.quarter, today: today).length,
        40,
      );
    });

    test('calcula mínimo, máximo, promedio y variación', () {
      final stats = HistoryStats.of([
        RatePoint(date: DateTime(2026, 10, 1), vesPerUnit: 100),
        RatePoint(date: DateTime(2026, 10, 2), vesPerUnit: 120),
        RatePoint(date: DateTime(2026, 10, 3), vesPerUnit: 110),
      ]);

      expect(stats.min, 100);
      expect(stats.max, 120);
      expect(stats.average, closeTo(110, 1e-9));
      expect(stats.change, 10);
      expect(stats.changePercent, closeTo(10, 1e-9));
    });

    test('un solo punto no tiene variación', () {
      final stats = HistoryStats.of([
        RatePoint(date: DateTime(2026, 10, 1), vesPerUnit: 100),
      ]);
      expect(stats.change, isNull);
      expect(stats.changePercent, isNull);
      expect(stats.average, 100);
    });
  });

  group('UsdtHistoryStore', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('guarda un valor por día y reemplaza el del mismo día', () async {
      final store = UsdtHistoryStore(prefs);

      await store.record(1000, DateTime(2026, 10, 26, 9));
      await store.record(1010, DateTime(2026, 10, 26, 20));
      await store.record(1020, DateTime(2026, 10, 27, 8));

      final points = store.read();
      expect(points.length, 2);
      expect(points.first.vesPerUnit, 1010);
      expect(points.last.vesPerUnit, 1020);
    });

    test('descarta valores viejos y entradas corruptas', () async {
      final store = UsdtHistoryStore(prefs);
      await prefs.setStringList(UsdtHistoryStore.key, [
        'no-es-una-entrada',
        '2026-06-01|900',
      ]);

      await store.record(1000, DateTime(2026, 10, 27));

      final points = store.read();
      expect(points.length, 1);
      expect(points.single.vesPerUnit, 1000);
    });
  });

  group('HistoryCache y repositorio', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('la caché guarda y recupera series', () async {
      final cache = HistoryCache(prefs);
      final now = DateTime(2026, 10, 27, 9);
      await cache.write({
        Currency.usd: daily(DateTime(2026, 10, 27), 3),
        Currency.eur: daily(DateTime(2026, 10, 27), 2, start: 900),
      }, now);

      final read = cache.read();
      expect(read, isNotNull);
      expect(read!.series[Currency.usd]!.length, 3);
      expect(read.series[Currency.eur]!.first.vesPerUnit, 900);
      expect(read.fetchedAt, now);
    });

    test('caché corrupta se ignora', () async {
      await prefs.setString(HistoryCache.key, 'no es json');
      expect(HistoryCache(prefs).read(), isNull);
    });

    test(
      'la primera carga descarga y guarda; la segunda usa la caché',
      () async {
        final client = _FakeClient(
          result: {
            Currency.usd: daily(DateTime.now(), 10),
            Currency.eur: daily(DateTime.now(), 10, start: 900),
          },
        );
        final repository = HistoryRepository(
          client,
          HistoryCache(prefs),
          UsdtHistoryStore(prefs),
        );

        final first = await repository.refresh(
          const HistorySnapshot(series: {}),
          force: true,
        );
        expect(first.series[Currency.usd]!.length, 10);
        expect(first.fromCache, isFalse);
        expect(client.calls, 1);

        final second = await repository.refresh(first);
        expect(second.fromCache, isTrue);
        expect(client.calls, 1);
      },
    );

    test(
      'si la red falla conserva la serie anterior y reporta el error',
      () async {
        await HistoryCache(prefs)
            .write({Currency.usd: daily(DateTime.now(), 5)}, DateTime.now());

        final repository = HistoryRepository(
          _FakeClient(error: RateError.network),
          HistoryCache(prefs),
          UsdtHistoryStore(prefs),
        );

        final snapshot = await repository.refresh(
          const HistorySnapshot(series: {}),
          force: true,
        );

        expect(snapshot.error, RateError.network);
        expect(snapshot.series[Currency.usd]!.length, 5);
        expect(snapshot.fromCache, isTrue);
      },
    );

    test('el USDT guardado se mezcla con el histórico del BCV', () async {
      final repository = HistoryRepository(
        _FakeClient(result: {Currency.usd: daily(DateTime.now(), 3)}),
        HistoryCache(prefs),
        UsdtHistoryStore(prefs),
      );
      await repository.recordUsdt(1005, DateTime.now());

      final snapshot = await repository.loadCached();
      expect(snapshot.series[Currency.usdt]!.single.vesPerUnit, 1005);
    });

    test('consulta una fecha del BCV y el snapshot local de USDT', () async {
      final point = RatePoint(date: DateTime(2025, 1, 2), vesPerUnit: 52.0);
      final client = _FakeClient(datePoint: point);
      final repository = HistoryRepository(
        client,
        HistoryCache(prefs),
        UsdtHistoryStore(prefs),
      );

      final bcv = await repository.fetchForDate(
        Currency.usd,
        DateTime(2025, 1, 2, 18),
      );
      expect(bcv, isNotNull);
      expect(bcv!.date, DateTime(2025, 1, 2));
      expect(client.lastDateRequested, DateTime(2025, 1, 2));

      await repository.recordUsdt(1005, DateTime(2026, 10, 26, 10));
      final usdt = await repository.fetchForDate(
        Currency.usdt,
        DateTime(2026, 10, 26, 22),
      );
      expect(usdt, isNotNull);
      expect(usdt!.vesPerUnit, 1005);
      expect(
        await repository.fetchForDate(Currency.usdt, DateTime(2026, 10, 25)),
        isNull,
      );
    });
  });
}
