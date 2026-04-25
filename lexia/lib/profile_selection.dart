import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_wrapper.dart';
import 'responsive_helper.dart';
import 'edit_child_page.dart';

class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  bool isEditMode = false;

  static const Color textDark = Color(0xFF2D3142);
  static const Color primaryPurple = Color(0xFF6A5ACD);

  static const Color ivoryWhite = Color(0xFFFFFDFB);
  static const Color paleBlush = Color(0xFFFFF9F9);
  static const Color softCream = Color(0xFFFFFAF5);

  Widget _avatarWidget(String? path, {double size = 95}) {
    final String src =
        (path == null || path.isEmpty) ? 'assets/lexiaAv.png' : path;

    if (src.startsWith('http')) {
      return Image.network(src, fit: BoxFit.cover);
    } else if (src.endsWith('.svg')) {
      return SvgPicture.asset(src, fit: BoxFit.contain);
    } else {
      return Image.asset(src, fit: BoxFit.cover);
    }
  }

  void _showPinDialog(BuildContext context, String correctPin) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter PIN"),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text == correctPin) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MainWrapper(isChildMode: false)),
                  (r) => false,
                );
              }
            },
            child: const Text("Enter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ivoryWhite, paleBlush, softCream, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER (logo + edit button)
              Padding(
                padding: EdgeInsets.only(top: R.space(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: R.space(40)),
                    Image.asset('assets/Lexia.png', width: R.s(85)),
                   GestureDetector(
  onTap: () {
    setState(() {
      isEditMode = !isEditMode;
    });
  },
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: R.s(42),
    height: R.s(42),
    decoration: BoxDecoration(
      color: isEditMode
          ? primaryPurple
          : Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(R.radius(12)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isEditMode
            ? primaryPurple
            : Colors.black.withOpacity(0.05),
      ),
    ),
    child: Icon(
      isEditMode ? Icons.check : Icons.edit,
      color: isEditMode ? Colors.white : primaryPurple,
      size: 20,
    ),
  ),
),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final userData =
                        userSnap.data?.data() as Map<String, dynamic>? ?? {};

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('children')
                          .snapshots(),
                      builder: (context, childSnap) {
                        final children = childSnap.data?.docs ?? [];

                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Text(
                                  "Who's learning today?",
                                  style: GoogleFonts.montserrat(
                                    fontSize: R.text(22),
                                  ),
                                ),
                                SizedBox(height: R.space(40)),

                                Wrap(
                                  spacing: R.space(25),
                                  runSpacing: R.space(35),
                                  alignment: WrapAlignment.center,
                                  children: [
                                    // 👩 Parent
                                    _buildProfileCard(
                                      name: userData['name'] ?? "Parent",
                                      role: "Parent 🔒",
                                      avatarPath: userData['avatarUrl'],
                                      isChild: false,
                                      onTap: () => _showPinDialog(
                                        context,
                                        (userData['pin'] ?? "0000")
                                            .toString(),
                                      ),
                                    ),

                                    // 👶 Children
                                    ...children.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;

                                      return _buildProfileCard(
                                        childId: doc.id,
                                        name: data['name'] ?? "Child",
                                        role: "child",
                                        avatarPath: data['avatarUrl'],
                                        isChild: true,
                                        onTap: () => Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MainWrapper(isChildMode: true),
                                          ),
                                          (r) => false,
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
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
    String? childId,
    required String name,
    required String role,
    required String? avatarPath,
    required bool isChild,
    required VoidCallback onTap,
  }) {
    final size = R.s(105);

    return GestureDetector(
      onTap: () async {
        if (isEditMode) {
          if (isChild && childId != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditChildPage(
                  name: name,
                  avatar: avatarPath ?? "",
                ),
              ),
            );

            if (result != null) {
              final uid = FirebaseAuth.instance.currentUser!.uid;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('children')
                  .doc(childId)
                  .update({
                'name': result["name"],
                'avatarUrl': result["avatar"],
              });
            }
          }
          return;
        } else {
          onTap();
        }
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _avatarWidget(avatarPath, size: size),
                ),
              ),

              if (isEditMode)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isChild ? Icons.edit : Icons.lock,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name),
          Text(role),
        ],
      ),
    );
  }
}