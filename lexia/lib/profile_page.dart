import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'add_child_popup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Function to delete a specific child
  Future<void> _deleteChild(String childDocId) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('children')
          .doc(childDocId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Child profile deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting child: $e");
    }
  }

  void _showDeleteConfirmation(String childName, String childDocId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Profile"),
        content: Text("Are you sure you want to delete $childName's profile?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              _deleteChild(childDocId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Simplified options menu with only the Delete action
  void _showChildOptions(String childName, String childDocId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Manage $childName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
              onTap: () => _showDeleteConfirmation(childName, childDocId),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF), // Matches your Figma bg color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/Lexia.png', height: 30),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(child: Text("Error: User profile not found."));
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('children').snapshots(),
            builder: (context, childSnap) {
              final bool hasChild = childSnap.hasData && childSnap.data!.docs.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // --- PARENT AVATAR HEADER ---
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [Color(0xFF8AABFF), Color(0xFFAC61FF)]),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                    userData['avatarUrl'] ?? "https://api.dicebear.com/9.x/fun-emoji/png?seed=parent",
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData['name'] ?? "Parent Name",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text("Parent Account", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- INFORMATION CARD ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.email_outlined, color: Colors.black54),
                            title: const Text("Email", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text(userData['email'] ?? "No email provided", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15)),
                          ),
                          const Divider(height: 1, indent: 50, color: Color(0xFFF3F4F6)),
                          const ListTile(
                            leading: Icon(Icons.shield_outlined, color: Colors.black54),
                            title: Text("PIN Protection", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text("Enabled", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- CHILD ACCOUNT SECTION ---
                    const Text(
                      "Child Account",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    
                    if (hasChild) ...[
                      // Figma Style Child Card
                      Builder(builder: (context) {
                        final childDoc = childSnap.data!.docs.first;
                        final childData = childDoc.data() as Map<String, dynamic>;
                        final childName = childData['name'] ?? "Child";
                        final childAvatar = childData['avatarUrl'] ?? "https://api.dicebear.com/9.x/fun-emoji/png?seed=child";
                        
                        return GestureDetector(
                          onTap: () => _showChildOptions(childName, childDoc.id), // Updated caller
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                              ]
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF52B69A), // Green background for avatar
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(childAvatar, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(childName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const Text("Child Profile", style: TextStyle(fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      // Add Child Button if none exists
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AddChildPopup(),
                        ),
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFFAC61FF)),
                        label: const Text("Add Child Account", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],

                    const Spacer(), // Pushes the Sign Out button to the bottom

                    // --- SIGN OUT BUTTON ---
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Red matching Figma
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                      label: const Text("Sign Out", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}