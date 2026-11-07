import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/theme/colors.dart';
import '../../providers.dart';

class ResultReadout extends StatefulWidget {
  const ResultReadout({super.key, required this.view});

  final ConversionView view;

  @override
  State<ResultReadout> createState() => _ResultReadoutState();
}

class _ResultReadoutState extends State<ResultReadout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(ResultReadout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view.result != oldWidget.view.result ||
        widget.view.to != oldWidget.view.to) {
      final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!disabled && widget.view.available) {
        _sweep.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _copyResult() async {
    final view = widget.view;
    if (!view.available || view.isEmpty) return;

    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: view.formattedResult));
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.raised,
        elevation: 0,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.line),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.mint,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Copiado al portapapeles',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final available = view.available;
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final value = view.result ?? 0;
    final canCopy = available && !view.isEmpty;

    final style = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 60,
      height: 0.98,
      fontWeight: FontWeight.w700,
      letterSpacing: -2.2,
      color: available ? AppColors.amber : AppColors.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: available
          ? [
              Shadow(
                color: AppColors.amber.withValues(alpha: 0.22),
                blurRadius: 24,
              ),
            ]
          : null,
    );

    return Semantics(
      liveRegion: true,
      button: canCopy,
      onTap: canCopy ? _copyResult : null,
      hint: canCopy ? 'Copia el resultado' : null,
      label: available
          ? 'Resultado: ${view.formattedResult}'
          : 'Resultado no disponible',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Equivale a',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.copy_rounded,
                    size: 11,
                    color: AppColors.muted.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 74,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canCopy ? _copyResult : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: value),
                      duration: disabled
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, animated, _) {
                        return Opacity(
                          opacity: view.isEmpty ? 0.55 : 1,
                          child: Text(
                            available
                                ? MoneyFormat.withCurrency(view.to, animated)
                                : '—',
                            style: style,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) {
                      final t = Curves.easeOutCubic.transform(_sweep.value);
                      if (t == 0) return const SizedBox.shrink();
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * t,
                          height: 1,
                          color: AppColors.amber.withValues(alpha: 1 - t),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 7),
            Text(
              view.to.label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
