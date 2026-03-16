import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_wrapper.dart';
import 'child_home_page.dart';

class ProfileSelectionPage extends StatelessWidget {
  const ProfileSelectionPage({super.key});

  // Function to show PIN dialog for Parent access
  void _showPinDialog(BuildContext context, String correctPin) {
    final TextEditingController _pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter PIN", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your 4-digit PIN to access the parent account",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: "", // Hides the character counter
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAC61FF),
            ),
            onPressed: () {
              if (_pinController.text == correctPin) {
                _pinController.clear();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainWrapper()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Incorrect PIN"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Enter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          // GUARD: Check if data is loading or document doesn't exist
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(
              child: Text("User data not found. Please log in again."),
            );
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('children')
                .snapshots(),
            builder: (context, childSnap) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/Lexia.png', width: 60),
                    const SizedBox(height: 40),
                    const Text(
                      "Who's learning\ntoday?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAC61FF),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PARENT PROFILE
                        _buildProfileItem(
                          name: userData['name'] ?? "Parent",
                          label: "Parent 🔒",
                          imageUrl:
                              userData['avatarUrl'] ??
                              "https://api.dicebear.com/9.x/fun-emoji/png?seed=parent",
                          onTap: () => _showPinDialog(
                            context,
                            (userData['pin'] ?? "0000").toString(),
                          ),
                        ),

                        // CHILD PROFILE (If exists in subcollection)
                        if (childSnap.hasData &&
                            childSnap.data!.docs.isNotEmpty) ...[
                          const SizedBox(width: 30),
                          Builder(
                            builder: (context) {
                              final childData =
                                  childSnap.data!.docs.first.data()
                                      as Map<String, dynamic>;
                              return _buildProfileItem(
                                name: childData['name'] ?? "Child",
                                label: "Child",
                                imageUrl:
                                    childData['avatarUrl'] ??
                                    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChildHomePage(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (childSnap.hasData && childSnap.data!.docs.isEmpty)
                      const Text(
                        "No child profiles yet. Go to Parent Profile to add one.",
                        style: TextStyle(color: Colors.black45, fontSize: 14),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileItem({
    required String name,
    required String label,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8AABFF), Color(0xFFAC61FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
