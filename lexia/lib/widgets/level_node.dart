import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class LevelNode extends StatefulWidget {
  final int level;
  final String title;
  final String status; // "completed", "current", "locked"
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

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Creates a continuous breathing/pulse effect for the active level
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrent = widget.status == "current";
    bool isLocked = widget.status == "locked";
    bool isCompleted = widget.status == "completed";

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The translucent "Current" badge from the photo
            if (isCurrent) _buildCurrentBadge(),

            // Stars appear above completed levels
            if (isCompleted) _buildStars(),

            // The main circle with pulse animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 75.w,
                  height: 75.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked ? Colors.grey[300] : widget.color,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        // Pulse logic: glow expands and fades based on animation controller
                        color: isCurrent
                            ? Colors.yellow.withOpacity(
                                0.2 + (_controller.value * 0.4),
                              )
                            : Colors.black12,
                        blurRadius: isCurrent
                            ? 12 + (_controller.value * 12)
                            : 10,
                        spreadRadius: isCurrent
                            ? 6 + (_controller.value * 6)
                            : 0,
                      ),
                    ],
                  ),
                  child: Center(child: _buildInsideIcon(isLocked, isCompleted)),
                );
              },
            ),

            SizedBox(height: 8.h),

            // Level Title
            Text(
              widget.title,
              style: GoogleFonts.fredoka(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsideIcon(bool isLocked, bool isCompleted) {
    if (isLocked) {
      return Icon(LucideIcons.lock, color: Colors.white, size: 26.sp);
    }
    if (isCompleted) {
      return Icon(LucideIcons.check, color: Colors.white, size: 32.sp);
    }
    return Text(
      "${widget.level}",
      style: GoogleFonts.fredoka(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 26.sp,
      ),
    );
  }

  Widget _buildCurrentBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      margin: EdgeInsets.only(bottom: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF5BAE94).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        "Current",
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Icon(Icons.star, size: 14.sp, color: Colors.amber),
        ),
      ),
    );
  }
}
