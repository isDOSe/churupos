import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chamfer.dart';
import '../../../../core/theme/colors.dart';

class SwapButton extends StatefulWidget {
  const SwapButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<SwapButton> {
  int _turns = 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Intercambiar monedas',
      child: ChamferPanel(
        cut: 10,
        color: AppColors.panel,
        borderColor: AppColors.ultra.withValues(alpha: 0.55),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _turns += 1);
                widget.onPressed();
              },
              child: Center(
                child: AnimatedRotation(
                  turns: _turns / 2,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 26,
                    color: AppColors.ultra,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
