import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main_wrapper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // الأخطاء لكل حقل
  final List<String> _nameErrors = [];
  final List<String> _emailErrors = [];
  final List<String> _passwordErrors = [];
  final List<String> _confirmPasswordErrors = [];
  final List<String> _pinErrors = [];

  Future<void> _handleSignUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String pin = _pinController.text.trim();

    // إعادة تهيئة القوائم
    _nameErrors.clear();
    _emailErrors.clear();
    _passwordErrors.clear();
    _confirmPasswordErrors.clear();
    _pinErrors.clear();

    // التحقق من الاسم
    if (name.isEmpty) _nameErrors.add("Name is required");
    if (name.length > 12) _nameErrors.add("Name must be at most 12 characters");

    // التحقق من البريد
    if (email.isEmpty) _emailErrors.add("Email is required");
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailErrors.add("Enter a valid email");
    }

    // التحقق من كلمة المرور
    if (password.isEmpty) _passwordErrors.add("Password is required");
    if (password.length < 8) _passwordErrors.add("At least 8 characters");
    if (!RegExp(r'[A-Z]').hasMatch(password))
      _passwordErrors.add("At least one uppercase letter");
    if (!RegExp(r'[a-z]').hasMatch(password))
      _passwordErrors.add("At least one lowercase letter");

    // التحقق من تأكيد كلمة المرور
    if (confirmPassword.isEmpty)
      _confirmPasswordErrors.add("Confirm your password");
    if (password != confirmPassword)
      _confirmPasswordErrors.add("Passwords do not match");

    // التحقق من PIN
    if (!RegExp(r'^\d{4}$').hasMatch(pin))
      _pinErrors.add("PIN must be exactly 4 digits");

    setState(() {});

    // إذا فيه أي أخطاء أوقف
    if (_nameErrors.isNotEmpty ||
        _emailErrors.isNotEmpty ||
        _passwordErrors.isNotEmpty ||
        _confirmPasswordErrors.isNotEmpty ||
        _pinErrors.isNotEmpty)
      return;

    setState(() => _isLoading = true);

    try {
      // إنشاء المستخدم في Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // حفظ البيانات الإضافية في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'pin': pin,
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
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
    _confirmPasswordController.dispose();
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
                        const SizedBox(height: 24),
                        _buildField(
                          "Your Name",
                          "John Doe",
                          _nameController,
                          _nameErrors,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          "Email",
                          "parent@example.com",
                          _emailController,
                          _emailErrors,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          "Password",
                          "........",
                          _passwordController,
                          _passwordErrors,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          "Confirm Password",
                          "........",
                          _confirmPasswordController,
                          _confirmPasswordErrors,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          "Parental PIN",
                          "1234",
                          _pinController,
                          _pinErrors,
                          isObscure: true,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAC61FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Log In",
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
            ),
          ),
        ),
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
    TextEditingController controller,
    List<String> errors, {
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errors.isNotEmpty ? Colors.red : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errors.isNotEmpty ? Colors.red : Colors.transparent,
              ),
            ),
          ),
        ),
        for (var err in errors)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              err,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    String hint,
    TextEditingController controller,
    List<String> errors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errors.isNotEmpty ? Colors.red : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errors.isNotEmpty ? Colors.red : Colors.transparent,
              ),
            ),
            suffixIcon: label.contains("Password")
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  )
                : null,
          ),
        ),
        for (var err in errors)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              err,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
