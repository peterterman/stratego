import 'package:flutter/material.dart';

class LakesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 10;
    final cellH = size.height / 10;

    _drawLakeLeft(canvas, cellW, cellH);
    _drawLakeRight(canvas, cellW, cellH);
  }

  void _drawLakeLeft(Canvas canvas, double cellW, double cellH) {
    final left = 2 * cellW;
    final top = 4 * cellH;
    final w = cellW * 2;
    final h = cellH * 2;

    _drawOrganicLake(
      canvas,
      left - cellW * 0.38,
      top - cellH * 0.28,
      w * 1.45,
      h * 1.35,
      flip: false,
    );
  }

  void _drawLakeRight(Canvas canvas, double cellW, double cellH) {
    final left = 6 * cellW;
    final top = 4 * cellH;
    final w = cellW * 2;
    final h = cellH * 2;

    _drawOrganicLake(
      canvas,
      left - cellW * 0.35,
      top - cellH * 0.26,
      w * 1.42,
      h * 1.32,
      flip: true,
    );
  }

  void _drawOrganicLake(
    Canvas canvas,
    double left,
    double top,
    double w,
    double h, {
    required bool flip,
  }) {
    final groundPaint = Paint()
      ..color = const Color(0xFF06420B)
      ..style = PaintingStyle.fill;

    final waterPaint = Paint()
      ..color = const Color(0xFF2FCFE0)
      ..style = PaintingStyle.fill;

    canvas.drawPath(_groundPath(left, top, w, h, flip), groundPaint);

    canvas.drawPath(
      _waterPath(left + w * 0.10, top + h * 0.10, w * 0.80, h * 0.80, flip),
      waterPaint,
    );
  }

  Path _groundPath(double left, double top, double w, double h, bool flip) {
    return _blobPath(left, top, w, h, flip, grow: 1.0);
  }

  Path _waterPath(double left, double top, double w, double h, bool flip) {
    return _blobPath(left, top, w, h, flip, grow: 0.92);
  }

  Path _blobPath(
    double left,
    double top,
    double w,
    double h,
    bool flip, {
    required double grow,
  }) {
    double x(double v) {
      final value = flip ? 1.0 - v : v;
      return left + w * value * grow + w * (1 - grow) / 2;
    }

    double y(double v) {
      return top + h * v * grow + h * (1 - grow) / 2;
    }

    final path = Path();

    path.moveTo(x(0.16), y(0.36));
    path.cubicTo(x(0.06), y(0.13), x(0.34), y(0.03), x(0.57), y(0.14));
    path.cubicTo(x(0.78), y(0.03), x(0.98), y(0.24), x(0.89), y(0.48));
    path.cubicTo(x(1.03), y(0.70), x(0.76), y(0.98), x(0.53), y(0.88));
    path.cubicTo(x(0.31), y(1.02), x(0.03), y(0.79), x(0.14), y(0.58));
    path.cubicTo(x(0.02), y(0.48), x(0.08), y(0.39), x(0.16), y(0.36));

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
