import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.voidBlack),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.95),
                radius: 1.15,
                colors: [Color(0x1A7C5CFF), Color(0x0007060B)],
                stops: [0, 0.65],
              ),
            ),
          ),
          const RepaintBoundary(
            child: CustomPaint(painter: _ScanlinesPainter()),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.voidBlack.withValues(alpha: 0),
                  AppColors.voidBlack.withValues(alpha: 0.55),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  const _ScanlinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.016)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter oldDelegate) => false;
}
