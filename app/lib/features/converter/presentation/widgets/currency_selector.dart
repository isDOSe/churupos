import 'package:flutter/material.dart';

import '../../../../core/theme/chamfer.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/currency.dart';
import '../../domain/rate_quote.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.currency,
    required this.quote,
    required this.onTap,
  });

  final Currency currency;
  final RateQuote? quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = quote != null;
    return Semantics(
      button: true,
      label: '${currency.label}. Toca para cambiar la moneda.',
      child: ChamferPanel(
        cut: 12,
        color: AppColors.panel,
        borderColor: AppColors.line,
        child: SizedBox(
          height: 92,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currency.code,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 25,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.7,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      available ? currency.label : 'Sin datos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: available ? AppColors.muted : AppColors.rose,
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
