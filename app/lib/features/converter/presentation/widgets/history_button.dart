import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chamfer.dart';
import '../../../../core/theme/colors.dart';

/// Acceso al histórico. Vive debajo de "Compartir cálculo" para que las dos
/// acciones de la pantalla estén juntas y el encabezado quede solo con la
/// marca y el refresco.
class HistoryButton extends StatelessWidget {
  const HistoryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver historial de la tasa',
      child: ChamferPanel(
        cut: 10,
        color: AppColors.panel,
        borderColor: AppColors.line,
        child: SizedBox(
          height: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onPressed();
              },
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 18,
                      color: AppColors.ultra,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Historial',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: AppColors.ink,
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
