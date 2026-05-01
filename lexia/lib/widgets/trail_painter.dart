import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrailPainter extends CustomPainter {
  final int currentLevel;

  TrailPainter({required this.currentLevel});

  @override
  void paint(Canvas canvas, Size size) {
    _drawFunBackground(canvas, size);
    _drawRoad(canvas, size);
    _drawDecorations(canvas, size);
  }

  void _drawFunBackground(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = const Color(0xFFFFE8F1).withOpacity(0.45);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      70.r,
      paint,
    );

    paint.color = const Color(0xFFEDE7FF).withOpacity(0.65);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.28),
      85.r,
      paint,
    );

    paint.color = const Color(0xFFFFF3C4).withOpacity(0.60);
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.58),
      80.r,
      paint,
    );

    paint.color = const Color(0xFFDFF7EF).withOpacity(0.65);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.75),
      95.r,
      paint,
    );

    _cloud(canvas, Offset(size.width * 0.18, size.height * 0.08), 0.85);
    _cloud(canvas, Offset(size.width * 0.78, size.height * 0.14), 0.65);
    _cloud(canvas, Offset(size.width * 0.18, size.height * 0.42), 0.55);
    _cloud(canvas, Offset(size.width * 0.80, size.height * 0.56), 0.60);
  }

  void _cloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withOpacity(0.72);

    canvas.drawCircle(center + Offset(-22 * scale, 0), 18 * scale, paint);
    canvas.drawCircle(center + Offset(0, -8 * scale), 24 * scale, paint);
    canvas.drawCircle(center + Offset(24 * scale, 0), 18 * scale, paint);

    final rect = Rect.fromCenter(
      center: center + Offset(0, 8 * scale),
      width: 70 * scale,
      height: 24 * scale,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(18 * scale)),
      paint,
    );
  }

  void _drawRoad(Canvas canvas, Size size) {
    final roadShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 68.w
      ..strokeCap = StrokeCap.round;

    final roadPaint = Paint()
      ..color = const Color(0xFFE8E1D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58.w
      ..strokeCap = StrokeCap.round;

    final sidePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5.w
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.w
      ..strokeCap = StrokeCap.round;

    final path = _roadPath(size);

    canvas.drawPath(path, roadShadowPaint);
    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, sidePaint);

    try {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0.0;

        while (distance < metric.length) {
          final extract = metric.extractPath(distance, distance + 12);
          canvas.drawPath(extract, dashPaint);
          distance += 30;
        }
      }
    } catch (_) {}
  }

  Path _roadPath(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.95);

    path.cubicTo(
      size.width * 0.08,
      size.height * 0.82,
      size.width * 0.92,
      size.height * 0.72,
      size.width * 0.5,
      size.height * 0.60,
    );

    path.cubicTo(
      size.width * 0.08,
      size.height * 0.50,
      size.width * 0.92,
      size.height * 0.40,
      size.width * 0.5,
      size.height * 0.30,
    );

    path.cubicTo(
      size.width * 0.18,
      size.height * 0.20,
      size.width * 0.82,
      size.height * 0.10,
      size.width * 0.5,
      size.height * 0.05,
    );

    return path;
  }

  void _drawDecorations(Canvas canvas, Size size) {
    _star(
      canvas,
      Offset(size.width * 0.80, size.height * 0.08),
      9,
      const Color(0xFFFFC857),
    );
    _star(
      canvas,
      Offset(size.width * 0.24, size.height * 0.28),
      7,
      const Color(0xFFF1B4AF),
    );
    _star(
      canvas,
      Offset(size.width * 0.78, size.height * 0.43),
      8,
      const Color(0xFF6A5ACD),
    );
    _star(
      canvas,
      Offset(size.width * 0.18, size.height * 0.72),
      8,
      const Color(0xFF59A685),
    );

    _flag(
      canvas,
      Offset(size.width * 0.55, size.height * 0.06),
      const Color(0xFFFACC15),
    );
    _flag(
      canvas,
      Offset(size.width * 0.25, size.height * 0.36),
      const Color(0xFFF1B4AF),
    );
    _flag(
      canvas,
      Offset(size.width * 0.74, size.height * 0.67),
      const Color(0xFF59A685),
    );
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color.withOpacity(0.75);
    final path = Path();

    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -1.57 + i * 0.628;
      final point = Offset(
        center.dx + r * MathCos.sin(angle + 1.57),
        center.dy - r * MathCos.cos(angle + 1.57),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _flag(Canvas canvas, Offset start, Color color) {
    final polePaint = Paint()
      ..color = const Color(0xFF2D3142).withOpacity(0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final flagPaint = Paint()..color = color.withOpacity(0.85);

    canvas.drawLine(start, start + const Offset(0, 34), polePaint);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(start.dx + 28, start.dy + 7)
      ..lineTo(start.dx, start.dy + 15)
      ..close();

    canvas.drawPath(path, flagPaint);
  }

  @override
  bool shouldRepaint(covariant TrailPainter oldDelegate) {
    return oldDelegate.currentLevel != currentLevel;
  }
}

class MathCos {
  static double sin(double value) {
    return _sin(value);
  }

  static double cos(double value) {
    return _cos(value);
  }

  static double _sin(double x) {
    return _approxSin(x);
  }

  static double _cos(double x) {
    return _approxSin(x + 1.57079632679);
  }

  static double _approxSin(double x) {
    while (x > 3.14159265359) {
      x -= 6.28318530718;
    }
    while (x < -3.14159265359) {
      x += 6.28318530718;
    }

    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
