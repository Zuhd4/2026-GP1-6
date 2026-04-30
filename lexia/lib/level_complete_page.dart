import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelCompletePage extends StatefulWidget {
  final int stars;

  const LevelCompletePage({super.key, required this.stars});

  @override
  State<LevelCompletePage> createState() => _LevelCompletePageState();
}

class _LevelCompletePageState extends State<LevelCompletePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);
  static const Color green = Color(0xFF59A685);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivoryWhite,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ivoryWhite, paleBlush, softCream, Colors.white],
              ),
            ),
          ),
          _buildConfetti(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.75, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/e_happy.png",
                                height: 145,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: primaryPurple.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.celebration_rounded,
                                      size: 62,
                                      color: primaryPurple,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Text(
                                "Level Complete!",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Amazing work! You earned",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textDark.withOpacity(0.65),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 500 + (index * 150),
                                    ),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Icon(
                                          index < widget.stars
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 52,
                                          color: index < widget.stars
                                              ? Colors.amber
                                              : Colors.grey.shade300,
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${widget.stars}/3 stars",
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter({required this.progress});

  final List<Color> colors = const [
    Color(0xFF6A5ACD),
    Color(0xFF59A685),
    Color(0xFFF1B4AF),
    Colors.amber,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(10);

    for (int i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -80 + random.nextDouble() * 120;
      final y = (startY + progress * (size.height + 180)) % (size.height + 80);

      paint.color = colors[i % colors.length].withOpacity(0.85);

      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: 8 + random.nextDouble() * 6,
        height: 12 + random.nextDouble() * 8,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6.28 + i);
      canvas.translate(-x, -y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
