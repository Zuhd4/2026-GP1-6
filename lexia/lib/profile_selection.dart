import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_wrapper.dart';
import 'responsive_helper.dart';

class ProfileSelectionPage extends StatelessWidget {
  const ProfileSelectionPage({super.key});

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);

  // --- ULTRA SOFT GRADIENT COLORS ---
  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  Widget _avatarWidget(String? path, {double size = 95}) {
    final String src = (path == null || path.isEmpty)
        ? 'assets/lexiaAv.png'
        : path;
    Widget imageContent;

    if (src.startsWith('http')) {
      imageContent = Image.network(
        src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/lexiaAv.png', fit: BoxFit.cover),
      );
    } else if (src.endsWith('.svg')) {
      imageContent = SvgPicture.asset(
        src,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      imageContent = Image.asset(
        src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/lexiaAv.png', fit: BoxFit.cover),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(24)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.radius(24)),
        child: imageContent,
      ),
    );
  }

  void _showPinDialog(BuildContext context, String correctPin) {
    final TextEditingController pinController = TextEditingController();
    String? pinError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.radius(24)),
          ),
          child: Padding(
            padding: EdgeInsets.all(R.space(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter PIN",
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(18),
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
                SizedBox(height: R.space(8)),
                Text(
                  "Enter your 4-digit PIN to access parent controls",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(12),
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: R.space(20)),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.montserrat(
                    fontSize: R.text(16),
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                  decoration: InputDecoration(
                    labelText: "Enter PIN",
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: R.text(14),
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F8),
                    counterText: "",
                    errorText: pinError,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: R.space(18),
                      horizontal: R.space(18),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.radius(16)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.radius(16)),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.radius(16)),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.radius(16)),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.4,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(R.radius(16)),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.6,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (pinError != null) {
                      setState(() {
                        pinError = null;
                      });
                    }
                  },
                ),
                SizedBox(height: R.space(24)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.montserrat(
                            color: Colors.black38,
                            fontWeight: FontWeight.w500,
                            fontSize: R.text(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: R.space(12)),
                    Expanded(
                      child: SizedBox(
                        height: R.buttonH(48),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(R.radius(14)),
                            ),
                          ),
                          onPressed: () {
                            if (pinController.text == correctPin) {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MainWrapper(isChildMode: false),
                                ),
                                (route) => false,
                              );
                            } else {
                              setState(() {
                                pinError = "Incorrect PIN";
                              });
                            }
                          },
                          child: Text(
                            "Enter",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w500,
                              fontSize: R.text(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: R.space(60)),
                child: Image.asset('assets/Lexia.png', width: R.s(85)),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryPurple),
                      );
                    }

                    final userData =
                        userSnap.data?.data() as Map<String, dynamic>? ?? {};

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('children')
                          .snapshots(),
                      builder: (context, childSnap) {
                        final List<DocumentSnapshot> children =
                            childSnap.hasData ? childSnap.data!.docs : [];

                        return Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Who's learning today?",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: R.text(22),
                                    fontWeight: FontWeight.w400,
                                    color: textDark.withOpacity(0.8),
                                  ),
                                ),
                                SizedBox(height: R.space(50)),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: R.space(30),
                                  ),
                                  child: Wrap(
                                    spacing: R.space(25),
                                    runSpacing: R.space(35),
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildProfileCard(
                                        name: userData['name'] ?? "Parent",
                                        role: "Parent 🔒",
                                        avatarPath: userData['avatarUrl'],
                                        onTap: () => _showPinDialog(
                                          context,
                                          (userData['pin'] ?? "0000")
                                              .toString(),
                                        ),
                                      ),
                                      ...children.map((doc) {
                                        final childData =
                                            doc.data() as Map<String, dynamic>;
                                        return _buildProfileCard(
                                          name: childData['name'] ?? "Child",
                                          role: "child",
                                          avatarPath: childData['avatarUrl'],
                                          onTap: () =>
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const MainWrapper(
                                                        isChildMode: true,
                                                      ),
                                                ),
                                                (route) => false,
                                              ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                                SizedBox(height: R.space(40)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String role,
    required String? avatarPath,
    required VoidCallback onTap,
  }) {
    final double cardSize = R.s(105);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(R.radius(26)),
              child: _avatarWidget(avatarPath, size: cardSize),
            ),
          ),
          SizedBox(height: R.space(12)),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: R.text(14),
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          SizedBox(height: R.space(5)),
          Text(
            role.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.black54,
              fontSize: R.text(9),
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
