import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/chamfer.dart';
import '../../../core/theme/colors.dart';
import '../domain/currency.dart';
import '../domain/rate_error.dart';
import '../domain/rate_quote.dart';
import '../domain/rates_state.dart';
import '../providers.dart';
import 'share_text.dart';
import 'sources_sheet.dart';
import 'widgets/amount_field.dart';
import 'widgets/app_background.dart';
import 'widgets/author_credit.dart';
import 'widgets/brand_header.dart';
import 'widgets/currency_selector.dart';
import 'widgets/currency_sheet.dart';
import 'widgets/rate_caption.dart';
import 'widgets/result_readout.dart';
import 'widgets/share_button.dart';
import 'widgets/swap_button.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen>
    with WidgetsBindingObserver {
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(ratesProvider.notifier).refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(ratesProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        notifier.resumeAutoRefresh();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        notifier.pauseAutoRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String? _errorText(RatesState? rates, ConversionView view) {
    if (rates == null || view.available) return null;
    if (rates.refreshing) return null;
    final error = rates.errorFor(view.from) ?? rates.errorFor(view.to);
    if (error == null) return 'No hay tasa disponible para este par.';
    return '${rateErrorMessage(error)}. Toca actualizar para reintentar.';
  }

  @override
  Widget build(BuildContext context) {
    final rateAsync = ref.watch(ratesProvider);
    final rates = rateAsync.value;
    final pair = ref.watch(pairProvider);
    final view = ref.watch(conversionProvider);
    final refreshing = rates?.refreshing ?? false;

    final quotes = Map<Currency, RateQuote>.from(
      rates?.quotes ?? const <Currency, RateQuote>{},
    );
    quotes.putIfAbsent(Currency.ves, () => RateQuote.baseVes(DateTime.now()));

    final horizontal = MediaQuery.sizeOf(context).width >= 400 ? 24.0 : 20.0;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(child: AppBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 12).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            10,
                            horizontal,
                            8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BrandHeader(
                                refreshing: refreshing,
                                onRefresh: () => ref
                                    .read(ratesProvider.notifier)
                                    .refresh(manual: true),
                              ),
                              const SizedBox(height: 28),
                              RepaintBoundary(
                                key: _shareKey,
                                child: _buildPanel(
                                  context: context,
                                  rates: rates,
                                  quotes: quotes,
                                  pair: pair,
                                  view: view,
                                  refreshing: refreshing,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ShareCalculationButton(
                                enabled: view.available && !view.isEmpty,
                                busy: _sharing,
                                onPressed: _shareCalculation,
                              ),
                              const SizedBox(height: 30),
                              const Spacer(),
                              _Footer(
                                onSources: () => showSourcesSheet(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCalculation() async {
    if (_sharing) return;
    final view = ref.read(conversionProvider);
    if (!view.available || view.isEmpty) return;

    setState(() => _sharing = true);
    ui.Image? captured;
    ui.Image? framed;

    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _shareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('No hay sección para capturar');
      }

      const pixelRatio = 3.0;
      const margin = 12.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      captured = image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final edge = (margin * pixelRatio).roundToDouble();
      final size = ui.Size(image.width + edge * 2, image.height + edge * 2);
      canvas.drawRect(
        ui.Offset.zero & size,
        ui.Paint()..color = AppColors.voidBlack,
      );
      canvas.drawImage(image, ui.Offset(edge, edge), ui.Paint());

      framed = await recorder.endRecording().toImage(
        size.width.round(),
        size.height.round(),
      );
      final data = await framed.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('No se pudo generar la imagen');

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'churupos-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          text: buildShareText(view),
          title: 'Compartir cálculo',
          subject: 'Churupos · ${view.formattedResult}',
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (error) {
      debugPrint('No se pudo compartir: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos compartir el cálculo. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      captured?.dispose();
      framed?.dispose();
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _buildPanel({
    required BuildContext context,
    required RatesState? rates,
    required Map<Currency, RateQuote> quotes,
    required PairState pair,
    required ConversionView view,
    required bool refreshing,
  }) {
    final errorText = _errorText(rates, view);
    final enabled = rates?.hasRemoteData ?? false;

    return ChamferPanel(
      cut: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2,
            child: refreshing
                ? const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.ultra,
                    backgroundColor: AppColors.line,
                  )
                : const ColoredBox(color: AppColors.line),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _SectionLabel('Desde')),
                    const SizedBox(width: 72),
                    Expanded(child: _SectionLabel('Hacia')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CurrencySelector(
                        currency: pair.from,
                        quote: quotes[pair.from],
                        onTap: () => showCurrencySheet(
                          context,
                          role: 'Desde',
                          selected: pair.from,
                          quotes: quotes,
                          onSelected: (currency) =>
                              ref.read(pairProvider.notifier).setFrom(currency),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SwapButton(
                      onPressed: () => ref.read(pairProvider.notifier).swap(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CurrencySelector(
                        currency: pair.to,
                        quote: quotes[pair.to],
                        onTap: () => showCurrencySheet(
                          context,
                          role: 'Hacia',
                          selected: pair.to,
                          quotes: quotes,
                          onSelected: (currency) =>
                              ref.read(pairProvider.notifier).setTo(currency),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AmountField(
                  value: pair.amount,
                  currency: pair.from,
                  enabled: enabled,
                  onChanged: (amount) =>
                      ref.read(pairProvider.notifier).setAmount(amount),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                ResultReadout(view: view),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                RateCaption(
                  view: view,
                  offline: rates?.fromCache ?? false,
                  errorText: errorText,
                ),
                if (!view.available &&
                    rates != null &&
                    !rates.refreshing &&
                    errorText != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => ref
                          .read(ratesProvider.notifier)
                          .refresh(manual: true),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.ultra,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Reintentar'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onSources});

  final VoidCallback onSources;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onSources,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.muted,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '¿De dónde salen estos valores?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.line,
            ),
          ),
        ),
        const SizedBox(height: 2),
        const AuthorCredit(),
      ],
    );
  }
}
