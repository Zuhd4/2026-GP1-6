import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color =
          const Color(0xFFE5E1D1) // Road color from photo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 55.w
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.w
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.95);

    // Three curves to support all 6 levels
    path.cubicTo(
      size.width * 0.1,
      size.height * 0.8,
      size.width * 0.9,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.cubicTo(
      size.width * 0.1,
      size.height * 0.5,
      size.width * 0.9,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.05,
    );

    canvas.drawPath(path, roadPaint);

    try {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0.0;
        while (distance < metric.length) {
          final extract = metric.extractPath(distance, distance + 10);
          canvas.drawPath(extract, dashPaint);
          distance += 25;
        }
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
