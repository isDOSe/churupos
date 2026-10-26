import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/colors.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.refreshing,
    required this.onRefresh,
  });

  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset(
            'assets/branding/churupos-mark.png',
            width: 40,
            height: 40,
            cacheWidth: 120,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Churupos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
        ),
        _RefreshButton(refreshing: refreshing, onPressed: onRefresh),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.refreshing, required this.onPressed});

  final bool refreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final border = refreshing
        ? AppColors.line
        : AppColors.ultra.withValues(alpha: 0.5);
    final foreground = refreshing ? AppColors.muted : AppColors.ink;

    return Semantics(
      button: true,
      enabled: !refreshing,
      label: 'Actualizar tasas',
      child: InkWell(
        onTap: refreshing
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed();
              },
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: refreshing
                ? Colors.transparent
                : AppColors.ultra.withValues(alpha: 0.06),
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (refreshing)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.4,
                    color: AppColors.ultra,
                  ),
                )
              else
                const Icon(
                  Icons.refresh_rounded,
                  size: 15,
                  color: AppColors.ultra,
                ),
              const SizedBox(width: 6),
              Text(
                'Actualizar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
