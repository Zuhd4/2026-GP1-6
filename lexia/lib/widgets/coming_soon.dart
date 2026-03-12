import 'package:flutter/material.dart';

class ComingSoonWidget extends StatelessWidget {
  final String title;

  const ComingSoonWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F8FF), // Matches your app background
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // A construction or "clock" icon looks professional for placeholders
          Icon(
            Icons.handyman_rounded,
            size: 80,
            color: Colors.purple.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFAC61FF),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This feature is coming soon!",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
