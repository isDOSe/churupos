import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/format/amount_input_formatter.dart';
import '../../core/format/money_format.dart';
import 'data/binance_p2p_client.dart';
import 'data/dolar_api_client.dart';
import 'data/rate_cache.dart';
import 'data/rate_repository.dart';
import 'domain/conversion.dart';
import 'domain/currency.dart';
import 'domain/rates_state.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences no inicializado'),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14; Churupos) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36',
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final rateRepositoryProvider = Provider<RatesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = ref.watch(dioProvider);
  return RateRepository(
    DolarApiClient(dio),
    BinanceP2pClient(dio),
    RateCache(prefs),
  );
});

final ratesProvider = AsyncNotifierProvider<RatesNotifier, RatesState>(
  RatesNotifier.new,
);

class RatesNotifier extends AsyncNotifier<RatesState> {
  static const Duration refreshEvery = Duration(minutes: 5);
  static const Duration manualCooldown = Duration(seconds: 5);

  Timer? _timer;

  @override
  Future<RatesState> build() async {
    final repository = ref.watch(rateRepositoryProvider);
    _startTimer();
    ref.onDispose(() => _timer?.cancel());

    return repository.loadCached();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(refreshEvery, (_) => refresh());
  }

  void pauseAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> resumeAutoRefresh() async {
    _startTimer();
    await refreshIfStale(refreshEvery);
  }

  Future<void> refresh({bool manual = false}) async {
    final current = state.value;
    if (current == null || current.refreshing) return;

    if (manual &&
        current.lastAttempt != null &&
        DateTime.now().difference(current.lastAttempt!) < manualCooldown) {
      return;
    }

    final repository = ref.read(rateRepositoryProvider);
    state = AsyncData(
      current.copyWith(refreshing: true, lastAttempt: DateTime.now()),
    );

    try {
      final next = await repository.refresh(current);
      state = AsyncData(next);
    } catch (_) {
      state = AsyncData(current.copyWith(refreshing: false));
    }
  }

  Future<void> refreshIfStale(Duration maxAge) async {
    final current = state.value;
    if (current == null || current.refreshing) return;
    final last = current.fetchedAt ?? current.lastAttempt;
    if (last == null || DateTime.now().difference(last) > maxAge) {
      await refresh();
    }
  }
}

class PairState {
  const PairState({required this.from, required this.to, required this.amount});

  final Currency from;
  final Currency to;

  /// Monto normalizado con coma decimal, sin separadores de miles.
  final String amount;

  double get value => parseAmount(amount);

  bool get isEmpty => amount.isEmpty || value == 0;

  PairState copyWith({Currency? from, Currency? to, String? amount}) {
    return PairState(
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
    );
  }
}

final pairProvider = NotifierProvider<PairNotifier, PairState>(
  PairNotifier.new,
);

class PairNotifier extends Notifier<PairState> {
  static const String _key = 'pair_v1';

  @override
  PairState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw);
        if (json is Map) {
          final from = Currency.fromCode(json['from']?.toString() ?? '');
          final to = Currency.fromCode(json['to']?.toString() ?? '');
          final amount = json['amount']?.toString() ?? '';
          if (from != null && to != null && from != to) {
            return PairState(from: from, to: to, amount: amount);
          }
        }
      } catch (_) {
        // Configuración corrupta: se usa el par por defecto.
      }
    }
    return const PairState(from: Currency.usd, to: Currency.ves, amount: '');
  }

  void setFrom(Currency currency) {
    if (currency == state.to) {
      swap();
      return;
    }
    if (currency == state.from) return;
    state = state.copyWith(from: currency);
    _persist();
  }

  void setTo(Currency currency) {
    if (currency == state.from) {
      swap();
      return;
    }
    if (currency == state.to) return;
    state = state.copyWith(to: currency);
    _persist();
  }

  void swap() {
    state = state.copyWith(from: state.to, to: state.from);
    _persist();
  }

  void setAmount(String amount) {
    state = state.copyWith(amount: amount);
    _persist();
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(
      prefs.setString(
        _key,
        jsonEncode({
          'from': state.from.code,
          'to': state.to.code,
          'amount': state.amount,
        }),
      ),
    );
  }
}

class ConversionView {
  const ConversionView({
    required this.from,
    required this.to,
    required this.amount,
    required this.result,
    required this.unitRate,
    required this.effectiveAt,
    required this.available,
    required this.stale,
    required this.isEmpty,
  });

  final Currency from;
  final Currency to;
  final double amount;
  final double? result;
  final double? unitRate;
  final DateTime? effectiveAt;
  final bool available;
  final bool stale;
  final bool isEmpty;

  String get formattedResult =>
      available && result != null ? MoneyFormat.withCurrency(to, result!) : '—';

  String get formattedRate {
    if (!available || unitRate == null) return 'Sin tasa disponible';
    return '1 ${from.code} = ${MoneyFormat.rate(to, unitRate!)}';
  }
}

final conversionProvider = Provider<ConversionView>((ref) {
  final pair = ref.watch(pairProvider);
  final rates = ref.watch(ratesProvider).value;
  final fromQuote = rates?.quotes[pair.from];
  final toQuote = rates?.quotes[pair.to];
  final available = fromQuote != null && toQuote != null;

  double? result;
  double? unitRate;
  DateTime? effectiveAt;
  var stale = false;

  if (available) {
    result = convert(pair.value, fromQuote, toQuote);
    unitRate = crossRate(fromQuote, toQuote);
    stale = fromQuote.stale || toQuote.stale || (rates?.fromCache ?? false);

    final times = <DateTime>[
      if (!pair.from.isBase) fromQuote.updatedAt,
      if (!pair.to.isBase) toQuote.updatedAt,
    ];
    effectiveAt = times.isEmpty
        ? rates?.fetchedAt
        : times.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  return ConversionView(
    from: pair.from,
    to: pair.to,
    amount: pair.value,
    result: result,
    unitRate: unitRate,
    effectiveAt: effectiveAt,
    available: available,
    stale: stale,
    isEmpty: pair.isEmpty,
  );
});
