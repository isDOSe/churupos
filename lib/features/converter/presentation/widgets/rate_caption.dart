import 'package:flutter/material.dart';

import '../../../../core/format/relative_time.dart';
import '../../../../core/theme/colors.dart';
import '../../providers.dart';

class RateCaption extends StatelessWidget {
  const RateCaption({
    super.key,
    required this.view,
    required this.offline,
    this.errorText,
  });

  final ConversionView view;
  final bool offline;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final dotColor = !view.available
        ? AppColors.rose
        : view.stale
        ? AppColors.amber
        : AppColors.mint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                view.formattedRate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: view.available ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
            if (view.effectiveAt != null) ...[
              const SizedBox(width: 8),
              Text(
                relativeTime(view.effectiveAt!),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
        if (offline && view.available) ...[
          const SizedBox(height: 7),
          const Text(
            'Sin conexión. Mostrando la última tasa guardada.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.amber,
            ),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 7),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.rose,
            ),
          ),
        ],
      ],
    );
  }
}
