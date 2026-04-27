import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../games_selection_page.dart';

class LevelNode extends StatelessWidget {
  final int level;
  final String title;
  final String status; // completed, current, locked
  final Color color;
  final Offset position;

  const LevelNode({
    super.key,
    required this.level,
    required this.title,
    required this.status,
    required this.color,
    required this.position,
  });

  void _handleTap(BuildContext context) {
    if (status == "locked") return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GamesSelectionPage(level: level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = status == "locked";

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey : color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.white)
                    : Text(
                        "$level",
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: isLocked ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
