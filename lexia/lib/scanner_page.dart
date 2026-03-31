import 'package:flutter/material.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  static const Color pageBg = Color(0xFFF9F7F4);
  static const Color primaryBlue = Color(0xFF5B96CA);
  static const Color primaryGreen = Color(0xFF59A685);
  static const Color softPeach = Color(0xFFF1B4AF);
  static const Color softYellow = Color(0xFFFCDA81);
  static const Color softPurple = Color(0xFFD8BDD9);
  static const Color softGrey = Color(0xFFF1F2F4);
  static const Color textDark = Color(0xFF2D3142);

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 54, color: primaryBlue),
              const SizedBox(height: 16),
              const Text(
                'Coming Soon 🚀',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This feature will be available soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                ),
                child: const Text("OK"),
              )
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
    return InkWell(
      onTap: () => _showComingSoon(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ التعديل هنا
            Icon(icon, color: textDark, size: 22),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: textDark, // ✅ بدل الأبيض
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xFF9C7BB6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryBlue.withOpacity(0.16)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scanner',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 20),

              _sectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: softPeach,
                              width: 5,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: primaryBlue,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Scan or upload an image',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: softGrey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "How it works:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _bulletItem('Scan text'),
                          _bulletItem('Upload image'),
                          _bulletItem('Convert text'),
                          _bulletItem('Send or download'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            context: context,
                            text: "Scan",
                            icon: Icons.camera_alt,
                            color: softPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            context: context,
                            text: "Upload",
                            icon: Icons.upload,
                            color: softPurple,
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
      ),
    );
  }
}