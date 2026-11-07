import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<RatesState> refresh(RatesState previous) async => state;
}

RatesState fixture() {
  final fetchedAt = DateTime(2026, 10, 28, 8, 15);
  return RatesState(
    quotes: {
      Currency.ves: RateQuote.baseVes(fetchedAt),
      Currency.usd: RateQuote(
        currency: Currency.usd,
        vesPerUnit: 886.2271,
        // El BCV publica con hora 00:00.
        updatedAt: DateTime(2026, 10, 28),
        source: RateSource.dolarApi,
      ),
      Currency.eur: RateQuote(
        currency: Currency.eur,
        vesPerUnit: 993.08836371,
        updatedAt: DateTime(2026, 10, 28),
        source: RateSource.dolarApi,
      ),
    },
    fetchedAt: fetchedAt,
    lastAttempt: fetchedAt,
  );
}

Future<ConversionView> viewFor(RatesState state) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      rateRepositoryProvider.overrideWithValue(_FakeRepository(state)),
    ],
  );
  addTearDown(container.dispose);

  await container.read(ratesProvider.future);
  return container.read(conversionProvider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'la hora del cálculo es la del último refresco, no la de la fuente',
    () async {
      final state = fixture();
      final view = await viewFor(state);

      expect(view.effectiveAt, state.fetchedAt);
      expect(view.effectiveAt, isNot(DateTime(2026, 10, 28)));
    },
  );

  test('sin fetchedAt usa la marca de la cotización', () async {
    final state = fixture();
    final withoutFetchedAt = RatesState(
      quotes: state.quotes,
      lastAttempt: state.lastAttempt,
    );

    final view = await viewFor(withoutFetchedAt);

    expect(view.effectiveAt, DateTime(2026, 10, 28));
  });
}
