import 'package:flutter/material.dart';

import '../../../core/platform/links.dart';
import '../../../core/theme/chamfer.dart';
import '../../../core/theme/colors.dart';
import 'widgets/sheet_shell.dart';

Future<void> showSourcesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.voidBlack.withValues(alpha: 0.72),
    isScrollControlled: true,
    builder: (sheetContext) {
      return SheetShell(
        showCredit: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'De dónde salen estos valores',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 18),
                _SourceBlock(
                  title: 'Dólar y euro BCV',
                  body:
                      'Banco Central de Venezuela, publicado por dolarapi.com.',
                  linkLabel: 've.dolarapi.com',
                  url: 'https://ve.dolarapi.com',
                ),
                Divider(height: 28),
                _SourceBlock(
                  title: 'Binance (USDT)',
                  body:
                      'Promedio de las 10 mejores ofertas de venta de USDT en '
                      'Binance P2P, calculado por Churupos al actualizar.',
                  linkLabel: 'p2p.binance.com',
                  url: 'https://p2p.binance.com',
                ),
                SizedBox(height: 24),
                Text(
                  'Churupos no fija, compra ni vende divisas. Los valores son '
                  'referenciales y pueden cambiar en cualquier momento. '
                  'Verifica siempre en la fuente antes de operar.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    height: 1.55,
                    color: AppColors.muted,
                  ),
                ),
                SizedBox(height: 22),
                _DoneButton(),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({
    required this.title,
    required this.body,
    required this.linkLabel,
    required this.url,
  });

  final String title;
  final String body;
  final String linkLabel;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            height: 1.5,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          link: true,
          child: InkWell(
            onTap: () => openExternalLink(url),
            child: Text(
              linkLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ultra,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.ultra,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton();

  @override
  Widget build(BuildContext context) {
    return ChamferPanel(
      cut: 10,
      color: AppColors.ultra,
      borderColor: AppColors.ultra,
      child: SizedBox(
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Center(
              child: Text(
                'Entendido',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
