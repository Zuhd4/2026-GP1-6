import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddChildPopup extends StatefulWidget {
  const AddChildPopup({super.key});

  @override
  State<AddChildPopup> createState() => _AddChildPopupState();
}

class _AddChildPopupState extends State<AddChildPopup> {
  final _nameController = TextEditingController();
  String _selectedAvatar =
      "https://api.dicebear.com/9.x/fun-emoji/png?seed=happy1&backgroundColor=b6e3f4";

  final List<String> avatars = [
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=happy1&backgroundColor=b6e3f4",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child2&backgroundColor=ffd5dc&mouth=cute&eyes=love",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child3&backgroundColor=ffdf7f&mouth=tongueOut&eyes=wink2",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child4&backgroundColor=71cf62&mouth=smileLol&eyes=shades",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child5&backgroundColor=f7c2f0&mouth=shy&eyes=cute",
    "https://api.dicebear.com/9.x/fun-emoji/png?seed=child6&backgroundColor=c0aede&mouth=lilSmile&eyes=wink",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding to handle keyboard when typing name
      padding: EdgeInsets.only(
        top: 32,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Child Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const Text(
              "Create a profile for your child",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Name Input
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Child's Name",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: "e.g., Alex",
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Avatar Selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Choose an Avatar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: avatars
                  .map(
                    (url) => GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = url),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _selectedAvatar == url
                                ? const Color(0xFF00C49A)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            // PREVIEW SECTION
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Preview",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _selectedAvatar,
                      height: 80,
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameController.text.isEmpty
                        ? "Child Name"
                        : _nameController.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C49A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('children')
                      .add({
                        'name': _nameController.text,
                        'avatarUrl': _selectedAvatar,
                        'parentId': uid,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  Navigator.pop(context);
                },
                child: const Text(
                  "Create Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
