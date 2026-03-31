import 'package:flutter/material.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  // ── Lexia Brand Palette ────────────────────────────────────────────────────
  static const Color pageBg = Color(0xFFFDF8F4);
  static const Color primaryBlue = Color(0xFF5B96CA);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color softPeach = Color(0xFFF1B4AF);
  static const Color softYellow = Color(0xFFFCDA81);
  static const Color softPurple = Color(0xFFD8BDD9);
  static const Color softGrey = Color(0xFFF3F4F8);
  static const Color textDark = Color(0xFF2D3142);

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: softYellow.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text("🚀", style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This feature will be available soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Got it!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDF5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFD4CDE8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4CDE8).withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: () => _showComingSoon(context),
          borderRadius: BorderRadius.circular(30),
          splashColor: const Color(0xFF6A5ACD).withOpacity(0.18),
          highlightColor: const Color(0xFF6A5ACD).withOpacity(0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textDark, size: 26),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepItem(String emoji, String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Plain title ─────────────────────────────────────────────────
              const Text(
                "Books",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Scan or upload any text image",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // ── Main card ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: softPurple.withOpacity(0.40),
                    width: 1.8,
                  ),
                ),
                child: Column(
                  children: [
                    // ── Gradient top section ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF3EBFF), Color(0xFFE8F4FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEDF5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD4CDE8),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4CDE8).withOpacity(0.6),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  color: Color(0xFF6A5ACD),
                                  size: 38,
                                ),
                              ),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: softYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text("✨",
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          const Expanded(
                            child: Text(
                              'Scan or upload\nan image',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ─────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // How it works
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: softGrey,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text("🗺️",
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text(
                                      "How it works",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _stepItem("📸", "Scan text", softPeach),
                                _stepItem("🖼️", "Upload image", primaryBlue),
                                _stepItem("🔤", "Convert text", primaryGreen),
                                _stepItem(
                                    "📤", "Send or download", softYellow),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: _actionButton(
                                  context: context,
                                  text: "Scan",
                                  icon: Icons.document_scanner_rounded,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionButton(
                                  context: context,
                                  text: "Upload",
                                  icon: Icons.cloud_upload_rounded,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}