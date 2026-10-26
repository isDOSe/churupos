import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final available = view.available;
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final value = view.result ?? 0;

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
      label: available
          ? 'Resultado: ${view.formattedResult}'
          : 'Resultado no disponible',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Equivale a',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 74,
              child: Align(
                alignment: Alignment.centerRight,
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
