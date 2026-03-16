import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_child_popup.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bool hasChild =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        if (hasChild) {
          // If a child exists, show the "Coming Soon" for the actual scanner
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  "Scanner feature\ncoming soon!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        } else {
          // If NO child exists, tell them to add one first
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_disabled_rounded,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "No Child Profile Found",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "You need to add a child profile from the Dashboard before you can use the scanner.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
