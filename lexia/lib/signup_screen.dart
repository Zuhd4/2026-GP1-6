import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  int _currentStep = 1;

  Future<void> _handleSignUp() async {
    // تحقق من الحقول في الخطوة 2
    if (_nameController.text.trim().isEmpty ||
        _pinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // إنشاء المستخدم في Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // حفظ البيانات الإضافية في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'pin': _pinController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // الانتقال إلى LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Authentication error")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Step $_currentStep of 2",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        if (_currentStep == 1) ...[
                          _buildField(
                            "Email",
                            "parent@example.com",
                            _emailController,
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            "Password",
                            "........",
                            _passwordController,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_emailController.text.trim().isEmpty ||
                                    _passwordController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Fill email and password"),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _currentStep = 2);
                              },
                              child: const Text("Next"),
                            ),
                          ),
                        ],
                        if (_currentStep == 2) ...[
                          _buildField("Your Name", "John Doe", _nameController),
                          const SizedBox(height: 12),
                          _buildField(
                            "Parental PIN",
                            "1234",
                            _pinController,
                            isObscure: true,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              child: const Text("Create Account"),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _currentStep = 1),
                            child: const Text("Back"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Full-screen loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildPasswordField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }
}
