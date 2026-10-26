import 'package:flutter/material.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/currency.dart';
import '../../domain/rate_quote.dart';
import 'sheet_shell.dart';

Future<void> showCurrencySheet(
  BuildContext context, {
  required String role,
  required Currency selected,
  required Map<Currency, RateQuote> quotes,
  required ValueChanged<Currency> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.voidBlack.withValues(alpha: 0.72),
    builder: (sheetContext) {
      return SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elegir moneda',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final currency in Currency.values)
              _CurrencyOption(
                currency: currency,
                quote: quotes[currency],
                selected: currency == selected,
                onTap: quotes.containsKey(currency) || currency.isBase
                    ? () {
                        Navigator.of(sheetContext).pop();
                        onSelected(currency);
                      }
                    : null,
              ),
          ],
        ),
      );
    },
  );
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.currency,
    required this.quote,
    required this.selected,
    required this.onTap,
  });

  final Currency currency;
  final RateQuote? quote;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = quote != null || currency.isBase;
    final rateLabel = !available
        ? 'Sin datos'
        : currency.isBase
        ? 'Base'
        : MoneyFormat.rate(Currency.ves, quote!.vesPerUnit);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: Text(
                currency.code,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: available ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                currency.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: available ? AppColors.muted : AppColors.rose,
                ),
              ),
            ),
            Text(
              rateLabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: available ? AppColors.ink : AppColors.rose,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 20,
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.ultra,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
