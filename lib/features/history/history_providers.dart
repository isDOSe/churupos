import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../converter/providers.dart';
import 'data/dolar_history_client.dart';
import 'data/history_cache.dart';
import 'data/history_repository.dart';
import 'data/usdt_history_store.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = ref.watch(dioProvider);
  return HistoryRepository(
    DolarHistoryClient(dio),
    HistoryCache(prefs),
    UsdtHistoryStore(prefs),
  );
});

final historyProvider = AsyncNotifierProvider<HistoryNotifier, HistorySnapshot>(
  HistoryNotifier.new,
  isAutoDispose: true,
);

class HistoryNotifier extends AsyncNotifier<HistorySnapshot> {
  @override
  Future<HistorySnapshot> build() async {
    final repository = ref.watch(historyRepositoryProvider);
    final cached = await repository.loadCached();
    return repository.refresh(cached);
  }

  Future<void> refresh({bool force = false}) async {
    // Mientras build() está cargando, ya hay una descarga en curso.
    if (state.isLoading && !state.hasValue) return;
    final repository = ref.read(historyRepositoryProvider);
    final current = state.value ?? await repository.loadCached();
    final next = await repository.refresh(current, force: force);
    if (!ref.mounted) return;
    state = AsyncData(next);
  }
}
