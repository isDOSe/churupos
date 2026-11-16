import 'package:flutter/material.dart';

import 'colors.dart';

Path chamferPath(Size size, double cut) {
  final double c = cut.clamp(0.0, size.shortestSide / 2);
  return Path()
    ..moveTo(c, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - c)
    ..lineTo(size.width - c, size.height)
    ..lineTo(0, size.height)
    ..lineTo(0, c)
    ..close();
}

class ChamferClipper extends CustomClipper<Path> {
  const ChamferClipper({required this.cut});

  final double cut;

  @override
  Path getClip(Size size) => chamferPath(size, cut);

  @override
  bool shouldReclip(ChamferClipper oldClipper) => oldClipper.cut != cut;
}

class _ChamferBorderPainter extends CustomPainter {
  const _ChamferBorderPainter({
    required this.cut,
    required this.color,
    required this.width,
  });

  final double cut;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = width / 2;
    final path = chamferPath(
      Size(size.width - width, size.height - width),
      cut,
    );
    canvas
      ..save()
      ..translate(inset, inset)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ChamferBorderPainter old) =>
      old.cut != cut || old.color != color || old.width != width;
}

class ChamferPanel extends StatelessWidget {
  const ChamferPanel({
    super.key,
    required this.child,
    this.color = AppColors.panel,
    this.borderColor = AppColors.line,
    this.cut = 16,
    this.borderWidth = 1,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final double cut;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _ChamferBorderPainter(
        cut: cut,
        color: borderColor,
        width: borderWidth,
      ),
      child: ClipPath(
        clipper: ChamferClipper(cut: cut),
        child: ColoredBox(color: color, child: child),
      ),
    );
  }
}
