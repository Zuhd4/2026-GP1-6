import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../games_selection_page.dart';

class LevelNode extends StatelessWidget {
  final int level;
  final String status;
  final Color color;
  final Offset position;
  final String childId;
  final bool hasTrophy;
  final int stars;

  const LevelNode({
    super.key,
    required this.level,
    required this.status,
    required this.color,
    required this.position,
    required this.childId,
    required this.hasTrophy,
    required this.stars,
  });

  void _handleTap(BuildContext context) {
    if (status == "locked") return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GamesSelectionPage(level: level, childId: childId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = status == "locked";
    final isCompleted = status == "completed";
    final isCurrent = status == "current";

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (isCurrent)
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.14),
                    ),
                  ),

                if (isCurrent)
                  Positioned(
                    top: -33,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car_filled_rounded,
                            color: Color(0xFF6A5ACD),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Go!",
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey.shade400 : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: isLocked
                            ? Colors.black.withOpacity(0.08)
                            : color.withOpacity(0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLocked
                        ? const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 30,
                          )
                        : isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 34,
                          )
                        : Text(
                            "$level",
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                  ),
                ),

                if (hasTrophy)
                  Positioned(
                    top: -9,
                    right: -8,
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                "Level $level",
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : const Color(0xFF2D3142),
                ),
              ),
            ),

            if (!isLocked && stars > 0) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: index < stars ? Colors.amber : Colors.grey.shade300,
                    size: 17,
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
