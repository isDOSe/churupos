import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_format.dart';
import '../../../core/format/relative_time.dart';
import '../../../core/format/short_date.dart';
import '../../../core/theme/chamfer.dart';
import '../../../core/theme/colors.dart';
import '../../converter/domain/currency.dart';
import '../../converter/domain/rate_error.dart';
import '../../converter/presentation/widgets/app_background.dart';
import '../../converter/presentation/widgets/author_credit.dart';
import '../../converter/providers.dart';
import '../domain/history_range.dart';
import '../domain/rate_history.dart';
import '../domain/rate_point.dart';
import '../history_providers.dart';
import 'widgets/rate_chart.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const List<Currency> _currencies = [
    Currency.usd,
    Currency.eur,
    Currency.usdt,
  ];

  late Currency _currency;
  HistoryRange _range = HistoryRange.month;
  int? _selected;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    final from = ref.read(pairProvider).from;
    _currency = from.isBase ? Currency.usd : from;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordTodayUsdt());
  }

  /// Binance no da histórico: si el usuario abre el historial antes del primer
  /// refresco del día, se guarda aquí el valor que ya está en pantalla.
  Future<void> _recordTodayUsdt() async {
    if (!mounted) return;
    final quote = ref.read(ratesProvider).value?.quotes[Currency.usdt];
    if (quote == null || quote.stale) return;
    await ref
        .read(historyRepositoryProvider)
        .recordUsdt(quote.vesPerUnit, quote.updatedAt);
    if (!mounted) return;
    await ref.read(historyProvider.notifier).refresh();
  }

  void _selectCurrency(Currency currency) {
    if (currency == _currency) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currency = currency;
      _selected = null;
    });
  }

  void _selectRange(HistoryRange range) {
    if (range == _range) return;
    HapticFeedback.selectionClick();
    setState(() {
      _range = range;
      _selected = null;
    });
  }

  Future<void> _reload() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await ref.read(historyProvider.notifier).refresh(force: true);
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final snapshot = historyAsync.value;
    final allPoints = snapshot?.pointsFor(_currency) ?? const <RatePoint>[];
    final points = pointsInRange(allPoints, _range);
    final stats = HistoryStats.of(points);
    final selectedIndex = points.isEmpty
        ? null
        : (_selected ?? points.length - 1).clamp(0, points.length - 1);
    final selected = selectedIndex == null ? null : points[selectedIndex];
    final loading = historyAsync.isLoading && snapshot == null;

    final horizontal = MediaQuery.sizeOf(context).width >= 400 ? 24.0 : 20.0;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
                  child: _TopBar(
                    refreshing: _refreshing,
                    onBack: () => Navigator.of(context).maybePop(),
                    onRefresh: _reload,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      24,
                      horizontal,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CurrencyTabs(
                          currencies: _currencies,
                          selected: _currency,
                          onSelected: _selectCurrency,
                        ),
                        const SizedBox(height: 14),
                        _RangeTabs(selected: _range, onSelected: _selectRange),
                        const SizedBox(height: 20),
                        ChamferPanel(
                          cut: 16,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                            child: loading
                                ? const _LoadingPanel()
                                : points.isEmpty
                                ? _EmptyPanel(
                                    currency: _currency,
                                    points: allPoints,
                                    error: snapshot?.error,
                                    onRetry: _reload,
                                  )
                                : _HistoryPanel(
                                    currency: _currency,
                                    range: _range,
                                    points: points,
                                    stats: stats,
                                    selected: selected,
                                    selectedIndex: selectedIndex,
                                    onSelect: (index) =>
                                        setState(() => _selected = index),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SourceNote(
                          currency: _currency,
                          points: allPoints,
                          fetchedAt: snapshot?.fetchedAt,
                          fromCache: snapshot?.fromCache ?? false,
                        ),
                        const SizedBox(height: 26),
                        const Center(
                          child: Text(
                            'Los valores son referenciales.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(child: AuthorCredit()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.refreshing,
    required this.onBack,
    required this.onRefresh,
  });

  final bool refreshing;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver',
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Historial',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
        ),
        _SquareButton(
          icon: Icons.refresh_rounded,
          label: 'Actualizar histórico',
          busy: refreshing,
          onPressed: refreshing ? null : onRefresh,
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ChamferPanel(
        cut: 8,
        color: AppColors.panel,
        borderColor: AppColors.line,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: AppColors.ultra,
                        ),
                      )
                    : Icon(icon, size: 19, color: AppColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyTabs extends StatelessWidget {
  const _CurrencyTabs({
    required this.currencies,
    required this.selected,
    required this.onSelected,
  });

  final List<Currency> currencies;
  final Currency selected;
  final ValueChanged<Currency> onSelected;

  String _label(Currency currency) => switch (currency) {
    Currency.usd => 'Dólar',
    Currency.eur => 'Euro',
    Currency.usdt => 'Binance',
    Currency.ves => 'Bolívar',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < currencies.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Tab(
              title: currencies[i].code,
              subtitle: _label(currencies[i]),
              selected: currencies[i] == selected,
              onTap: () => onSelected(currencies[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: ChamferPanel(
        cut: 8,
        color: selected
            ? AppColors.ultra.withValues(alpha: 0.12)
            : AppColors.panel,
        borderColor: selected
            ? AppColors.ultra.withValues(alpha: 0.65)
            : AppColors.line,
        child: SizedBox(
          height: 52,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: selected ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      height: 1.1,
                      color: selected
                          ? AppColors.ink.withValues(alpha: 0.72)
                          : AppColors.muted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.selected, required this.onSelected});

  final HistoryRange selected;
  final ValueChanged<HistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final range in HistoryRange.values) ...[
          if (range != HistoryRange.values.first) const SizedBox(width: 6),
          Semantics(
            button: true,
            selected: range == selected,
            label: 'Últimos ${range.label}',
            child: InkWell(
              onTap: () => onSelected(range),
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: range == selected
                      ? AppColors.raised
                      : Colors.transparent,
                  border: Border.all(
                    color: range == selected ? AppColors.ultra : AppColors.line,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    range.shortLabel,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      color: range == selected
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.currency,
    required this.range,
    required this.points,
    required this.stats,
    required this.selected,
    required this.selectedIndex,
    required this.onSelect,
  });

  final Currency currency;
  final HistoryRange range;
  final List<RatePoint> points;
  final HistoryStats stats;
  final RatePoint? selected;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final point = selected;
    final change = stats.change;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              point == null ? '' : relativeDay(point.date),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Text(
              'Bs. por 1 ${currency.code}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (point != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormat.number(point.vesPerUnit),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                color: AppColors.ink,
              ),
            ),
          ),
        if (stats.changePercent != null && change != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _DeltaBadge(percent: stats.changePercent!),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${MoneyFormat.number(change.abs())} Bs. '
                  '${change >= 0 ? 'más' : 'menos'} en ${range.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        RateChart(
          points: points,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Mínimo',
                value: MoneyFormat.number(stats.min!),
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Máximo',
                value: MoneyFormat.number(stats.max!),
              ),
            ),
            Expanded(
              child: _StatTile(
                label: 'Promedio',
                value: MoneyFormat.number(stats.average!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    final color = up ? AppColors.mint : AppColors.rose;
    final text = percent.abs().toStringAsFixed(1).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${up ? '+' : '-'}$text %',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 236,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            color: AppColors.ultra,
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.currency,
    required this.points,
    required this.error,
    required this.onRetry,
  });

  final Currency currency;
  final List<RatePoint> points;
  final RateError? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isUsdt = currency == Currency.usdt;
    final failed = error != null && !isUsdt;

    final title = isUsdt
        ? points.isEmpty
              ? 'Todavía no hay historial de USDT'
              : 'Solo hay un valor de USDT'
        : 'No pudimos cargar el histórico';

    final body = isUsdt
        ? points.isEmpty
              ? 'Binance P2P no publica precios anteriores. Churupos guarda un '
                    'valor por día cada vez que actualiza las tasas, así que la '
                    'línea aparecerá en los próximos días.'
              : 'El primer valor se guardó el ${shortDate(points.first.date)}. '
                    'La línea aparece cuando haya al menos dos días con datos.'
        : '${rateErrorMessage(error ?? RateError.network)}. Revisa tu conexión '
              'e inténtalo de nuevo.';

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 220),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timeline_rounded,
              size: 26,
              color: AppColors.ultra,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ),
            if (failed && !isUsdt) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ultra,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({
    required this.currency,
    required this.points,
    required this.fetchedAt,
    required this.fromCache,
  });

  final Currency currency;
  final List<RatePoint> points;
  final DateTime? fetchedAt;
  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (currency == Currency.usdt) {
      final since = points.isEmpty
          ? ''
          : ' Historial local desde el ${shortDate(points.first.date)}.';
      text =
          'El promedio P2P lo calcula Churupos en cada actualización.'
          '$since';
    } else {
      final cached = fromCache ? ' Datos guardados en el teléfono.' : '';
      final updated = fetchedAt == null
          ? ''
          : ' Actualizado ${relativeTime(fetchedAt!)}.';
      text = 'BCV vía dolarapi.com.$cached$updated';
    }

    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10.5,
        height: 1.5,
        color: AppColors.muted,
      ),
    );
  }
}
