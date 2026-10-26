import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chamfer.dart';
import '../../../../core/theme/colors.dart';

class ShareCalculationButton extends StatelessWidget {
  const ShareCalculationButton({
    super.key,
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    final foreground = enabled ? AppColors.ink : AppColors.muted;

    return Semantics(
      button: true,
      enabled: active,
      label: 'Compartir cálculo',
      child: ChamferPanel(
        cut: 10,
        color: AppColors.panel,
        borderColor: enabled
            ? AppColors.ultra.withValues(alpha: 0.55)
            : AppColors.line,
        child: SizedBox(
          height: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: active
                  ? () {
                      HapticFeedback.selectionClick();
                      onPressed();
                    }
                  : null,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: AppColors.ultra,
                        ),
                      )
                    else
                      Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: enabled ? AppColors.ultra : AppColors.muted,
                      ),
                    const SizedBox(width: 9),
                    Text(
                      'Compartir cálculo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
