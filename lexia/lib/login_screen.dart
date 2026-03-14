import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth
import 'signup_screen.dart';
import 'main_wrapper.dart';
=======
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
<<<<<<< HEAD
  // 1. Controllers and State
=======
  // 2. Define your controllers and variables here
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

<<<<<<< HEAD
  // 2. Sign In Logic
  Future<void> _handleLogin() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Sign In
=======
  // Logic for logging in
  Future<void> _login() async {
    setState(() => _isLoading = true); // Start spinner
    try {
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
<<<<<<< HEAD

      // Navigate to MainWrapper on success
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Errors (e.g., wrong password, user not found)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Authentication failed")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
=======
      // Navigate to home or dashboard on success
    } on FirebaseAuthException catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
    } finally {
      setState(() => _isLoading = false); // Stop spinner
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
    }
  }

  @override
  void dispose() {
<<<<<<< HEAD
    // Clean up controllers to save memory
=======
    // Clean up controllers when the widget is removed
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Centered Logo
              Image.asset('assets/Lexia.png', width: 140),
              const SizedBox(height: 10),
              const Text(
                "This is the Owner Account",
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
              const SizedBox(height: 30),

              // 2. The Styled Card
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const Text(
                      "Sign in to continue",
                      style: TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // Email Field - Now linked to Controller
                    _buildTextField(
                      label: "Email",
                      hint: "parent@example.com",
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),

                    // Password Field - Now linked to Controller
                    _buildTextField(
                      label: "Password",
                      hint: "........",
                      isObscure: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 32),

                    // Sign In Button
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
                        // Changed to call Firebase Login
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Color(0xFF5B86FD),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
=======
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text("Login")),
          ],
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
        ),
      ),
    );
  }
<<<<<<< HEAD

  // Helper function - Updated to accept a controller
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Linked controller
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
=======
>>>>>>> 7823348e8f631a8ac80871ffc64674fa9b8b314c
}
