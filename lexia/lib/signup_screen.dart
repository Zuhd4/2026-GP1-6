import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_wrapper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
<<<<<<< HEAD
  // 1. Controllers to capture the data from your UI
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController(); // Added PIN controller

  bool _isLoading = false;

  // 2. Sign Up Logic
  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Save additional data (Name & PIN) to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'pin': _pinController.text.trim(), // Save the PIN
            'createdAt': DateTime.now(),
          });

      // Navigate to MainWrapper on success
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "An error occurred")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
=======
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> createUserWithEmailAndPassword() async {
    try {
      final UserCredential = FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error creating account")),
      );
    }
    print(UserCredential);
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
  }

  @override
  void dispose() {
<<<<<<< HEAD
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
=======
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep your layout exactly the same
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Lexia.png', width: 120),
              const SizedBox(height: 30),

              Container(
                width: 340,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const Text(
                      "Join Lexia today!",
                      style: TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

<<<<<<< HEAD
                    // Linked to Controllers
                    _buildField("Your Name", "John Doe", _nameController),
                    const SizedBox(height: 12),
                    _buildField(
                      "Email",
                      "parent@example.com",
                      _emailController,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      "Password",
                      "........",
                      _passwordController,
                      isObscure: true,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      "Parental PIN",
                      "1234",
                      _pinController,
                      isObscure: true,
=======
                    _buildField(
                      "Your Name",
                      "John Doe",
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      "Email",
                      "parent@example.com",
                      controller: emailController,
                    ),
                    const SizedBox(height: 12),

                    _buildField(
                      "Password",
                      "........",
                      isObscure: true,
                      controller: passwordController,
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAC61FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
<<<<<<< HEAD
                        // Call the Sign Up logic here
                        onPressed: _isLoading ? null : _handleSignUp,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
=======
                        onPressed: () async {
                          await createUserWithEmailAndPassword();
                        },
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
                      ),
                    ),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Already have an account? Sign In",
                        style: TextStyle(color: Color(0xFF5B86FD)),
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

<<<<<<< HEAD
  // Updated helper to accept a controller
  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isObscure = false,
=======
  Widget _buildField(
    String label,
    String hint, {
    bool isObscure = false,
    required TextEditingController controller,
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
<<<<<<< HEAD
          controller: controller, // Linked the controller here
=======
          controller: controller,
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
