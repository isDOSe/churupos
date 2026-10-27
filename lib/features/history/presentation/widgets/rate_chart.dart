import 'package:flutter/material.dart';

import '../../../../core/format/short_date.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/rate_point.dart';

/// Gráfico de línea del histórico diario. Tocar o arrastrar mueve el cursor y
/// avisa qué punto se está mirando.
class RateChart extends StatelessWidget {
  const RateChart({
    super.key,
    required this.points,
    required this.selectedIndex,
    required this.onSelect,
    this.height = 190,
  });

  static const double leftPad = 4;
  static const double rightPad = 4;
  static const double topPad = 12;
  static const double bottomPad = 22;

  final List<RatePoint> points;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final double height;

  void _select(double dx, double width) {
    if (points.length < 2) return;
    final usable = width - leftPad - rightPad;
    if (usable <= 0) return;
    final fraction = ((dx - leftPad) / usable).clamp(0.0, 1.0);
    onSelect((fraction * (points.length - 1)).round());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          label:
              'Gráfico de ${points.length} días. '
              'Arrastra para ver cada valor.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _select(details.localPosition.dx, width),
            onHorizontalDragStart: (details) =>
                _select(details.localPosition.dx, width),
            onHorizontalDragUpdate: (details) =>
                _select(details.localPosition.dx, width),
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: _RateChartPainter(
                  points: points,
                  selectedIndex: selectedIndex,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RateChartPainter extends CustomPainter {
  const _RateChartPainter({required this.points, required this.selectedIndex});

  final List<RatePoint> points;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      RateChart.leftPad,
      RateChart.topPad,
      size.width - RateChart.rightPad,
      size.height - RateChart.bottomPad,
    );
    if (points.isEmpty || plot.width <= 0 || plot.height <= 0) return;

    _paintGrid(canvas, plot);
    _paintDates(canvas, plot, size);

    if (points.length == 1) {
      _paintDot(canvas, plot.center, AppColors.ultra);
      return;
    }

    final bounds = _bounds();
    double xFor(int index) =>
        plot.left + plot.width * index / (points.length - 1);
    double yFor(double value) =>
        plot.bottom -
        plot.height * (value - bounds.$1) / (bounds.$2 - bounds.$1);

    final line = Path()..moveTo(xFor(0), yFor(points.first.vesPerUnit));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(xFor(i), yFor(points[i].vesPerUnit));
    }

    final area = Path.from(line)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3D7C5CFF), Color(0x007C5CFF)],
        ).createShader(plot),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.ultra.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.ultra
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final index = (selectedIndex ?? points.length - 1).clamp(
      0,
      points.length - 1,
    );
    final point = Offset(xFor(index), yFor(points[index].vesPerUnit));

    _dashedLine(
      canvas,
      Offset(point.dx, plot.top),
      Offset(point.dx, plot.bottom),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.22)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      point,
      10,
      Paint()..color = AppColors.ultra.withValues(alpha: 0.16),
    );
    _paintDot(canvas, point, AppColors.ultra);
  }

  /// Devuelve `(mínimo, máximo)` con un 10 % de aire para que la línea no
  /// toque los bordes.
  (double, double) _bounds() {
    var min = points.first.vesPerUnit;
    var max = min;
    for (final point in points) {
      if (point.vesPerUnit < min) min = point.vesPerUnit;
      if (point.vesPerUnit > max) max = point.vesPerUnit;
    }

    if (max == min) {
      final pad = min.abs() * 0.01 + 0.01;
      return (min - pad, max + pad);
    }
    final pad = (max - min) * 0.12;
    return (min - pad, max + pad);
  }

  void _paintGrid(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = plot.top + plot.height * i / 2;
      _dashedLine(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        paint,
        dash: 4,
        gap: 5,
      );
    }
  }

  void _paintDates(Canvas canvas, Rect plot, Size size) {
    if (points.length < 2) return;

    _label(
      canvas,
      shortDate(points.first.date),
      Offset(plot.left, size.height - RateChart.bottomPad + 7),
    );

    final last = points.last.date;
    final lastLabel = shortDate(last);
    _label(
      canvas,
      lastLabel,
      Offset(plot.right, size.height - RateChart.bottomPad + 7),
      alignRight: true,
    );

    if (points.length > 2 && plot.width > 210) {
      final middle = points[points.length ~/ 2].date;
      final label = shortDate(middle);
      if (label != lastLabel) {
        _label(
          canvas,
          label,
          Offset(plot.center.dx, size.height - RateChart.bottomPad + 7),
          centered: true,
        );
      }
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = centered
        ? anchor.dx - painter.width / 2
        : alignRight
        ? anchor.dx - painter.width
        : anchor.dx;
    painter.paint(canvas, Offset(dx, anchor.dy));
  }

  void _paintDot(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 4.5, Paint()..color = AppColors.voidBlack);
    canvas.drawCircle(
      center,
      4.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _dashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dash = 3,
    double gap = 4,
  }) {
    final total = (to - from).distance;
    if (total <= 0) return;
    final direction = (to - from) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final end = (drawn + dash).clamp(0.0, total);
      canvas.drawLine(from + direction * drawn, from + direction * end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_RateChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex;
}
