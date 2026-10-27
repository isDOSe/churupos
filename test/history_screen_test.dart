import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:churupos/features/converter/domain/currency.dart';
import 'package:churupos/features/converter/providers.dart';
import 'package:churupos/features/history/data/dolar_history_client.dart';
import 'package:churupos/features/history/data/history_cache.dart';
import 'package:churupos/features/history/data/history_repository.dart';
import 'package:churupos/features/history/data/usdt_history_store.dart';
import 'package:churupos/features/history/domain/rate_point.dart';
import 'package:churupos/features/history/history_providers.dart';
import 'package:churupos/features/history/presentation/history_screen.dart';

class _FakeHistoryRepository extends HistoryRepository {
  _FakeHistoryRepository(SharedPreferences prefs, this.snapshot)
    : super(
        DolarHistoryClient(Dio()),
        HistoryCache(prefs),
        UsdtHistoryStore(prefs),
      );

  final HistorySnapshot snapshot;

  @override
  Future<HistorySnapshot> loadCached() async => snapshot;

  @override
  Future<HistorySnapshot> refresh(
    HistorySnapshot previous, {
    bool force = false,
  }) async => snapshot;

  @override
  Future<void> recordUsdt(double vesPerUnit, DateTime at) async {}
}

List<RatePoint> series(DateTime end, int days, double start, double step) => [
  for (var i = days - 1; i >= 0; i--)
    RatePoint(
      date: end.subtract(Duration(days: i)),
      vesPerUnit: start + step * (days - 1 - i),
    ),
];

void main() {
  testWidgets('muestra el histórico del BCV y permite cambiar de moneda', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final snapshot = HistorySnapshot(
      series: {
        Currency.usd: series(today, 40, 850, 0.9),
        Currency.eur: series(today, 40, 950, 1.1),
      },
      fetchedAt: today,
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyRepositoryProvider.overrideWithValue(
            _FakeHistoryRepository(prefs, snapshot),
          ),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Bs. por 1 USD'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('Mínimo'), findsOneWidget);
    expect(find.text('Máximo'), findsOneWidget);

    await tester.tap(find.text('USDT'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay historial de USDT'), findsOneWidget);
  });

  testWidgets('cambiar a 7 días mantiene la serie y el resumen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final snapshot = HistorySnapshot(
      series: {Currency.usd: series(today, 40, 850, 0.9)},
      fetchedAt: today,
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyRepositoryProvider.overrideWithValue(
            _FakeHistoryRepository(prefs, snapshot),
          ),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('7D'));
    await tester.pumpAndSettle();

    expect(find.text('7D'), findsOneWidget);
    expect(find.text('Mínimo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cabe en un teléfono de 320 px sin desbordarse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final snapshot = HistorySnapshot(
      series: {Currency.usd: series(today, 40, 850, 0.9)},
      fetchedAt: today,
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyRepositoryProvider.overrideWithValue(
            _FakeHistoryRepository(prefs, snapshot),
          ),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('USDT'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay historial de USDT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
