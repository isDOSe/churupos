import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:churupos/app.dart';
import 'package:churupos/features/converter/data/rate_repository.dart';
import 'package:churupos/features/converter/domain/currency.dart';
import 'package:churupos/features/converter/domain/rate_quote.dart';
import 'package:churupos/features/converter/domain/rates_state.dart';
import 'package:churupos/features/converter/providers.dart';

class _FakeRepository implements RatesRepository {
  _FakeRepository(this.state);

  final RatesState state;

  @override
  Future<RatesState> loadCached() async => state;

  @override
  Future<RatesState> refresh(RatesState previous) async =>
      state.copyWith(lastAttempt: DateTime.now());
}

RatesState fixture({bool fromCache = false}) {
  final now = DateTime(2026, 10, 23, 9, 41);
  return RatesState(
    quotes: {
      Currency.ves: RateQuote.baseVes(now),
      Currency.usd: RateQuote(
        currency: Currency.usd,
        vesPerUnit: 886.2271,
        updatedAt: DateTime(2026, 10, 23),
        source: RateSource.dolarApi,
        stale: fromCache,
      ),
      Currency.eur: RateQuote(
        currency: Currency.eur,
        vesPerUnit: 993.08836371,
        updatedAt: DateTime(2026, 10, 23),
        source: RateSource.dolarApi,
        stale: fromCache,
      ),
      Currency.usdt: RateQuote(
        currency: Currency.usdt,
        vesPerUnit: 1000.616,
        updatedAt: now,
        source: RateSource.binanceP2p,
        stale: fromCache,
      ),
    },
    fetchedAt: now,
    lastAttempt: now,
    fromCache: fromCache,
  );
}

Future<void> pumpApp(WidgetTester tester, {required RatesState state}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        rateRepositoryProvider.overrideWithValue(_FakeRepository(state)),
      ],
      child: const ChuruposApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre en dólar BCV a bolívares y calcula 30', (tester) async {
    await pumpApp(tester, state: fixture());

    expect(find.text('Churupos'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('1 USD = Bs. 886,23'), findsOneWidget);
    expect(find.text('Bs. 0,00'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '30');
    await tester.pumpAndSettle();

    expect(find.text('Bs. 26.586,81'), findsOneWidget);
    expect(find.text('Compartir cálculo'), findsOneWidget);
  });

  testWidgets('el botón central intercambia y recalcula', (tester) async {
    await pumpApp(tester, state: fixture());

    await tester.enterText(find.byType(TextField), '30');
    await tester.pumpAndSettle();
    expect(find.text('Bs. 26.586,81'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('1 VES = \$ 0,0011'), findsOneWidget);
    expect(find.text('\$ 0,03'), findsOneWidget);
  });

  testWidgets('elige moneda desde la hoja inferior', (tester) async {
    await pumpApp(tester, state: fixture());

    await tester.tap(find.text('Dólar BCV'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir moneda'), findsOneWidget);
    expect(find.text('Euro BCV'), findsOneWidget);

    await tester.tap(find.text('Euro BCV'));
    await tester.pumpAndSettle();

    expect(find.text('1 EUR = Bs. 993,09'), findsOneWidget);
  });

  testWidgets('la hoja de fuentes explica el origen y el descargo', (
    tester,
  ) async {
    await pumpApp(tester, state: fixture());

    final button = find.text('¿De dónde salen estos valores?');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('De dónde salen estos valores'), findsOneWidget);
    expect(find.text('ve.dolarapi.com'), findsOneWidget);
    expect(find.text('p2p.binance.com'), findsOneWidget);
    expect(find.textContaining('Churupos no fija'), findsOneWidget);
    expect(find.text('Hecho por isdose.com'), findsWidgets);
  });

  testWidgets('con caché muestra sin conexión y sigue calculando', (
    tester,
  ) async {
    await pumpApp(tester, state: fixture(fromCache: true));

    expect(find.textContaining('Sin conexión'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '10');
    await tester.pumpAndSettle();
    expect(find.text('Bs. 8.862,27'), findsOneWidget);
  });
}
