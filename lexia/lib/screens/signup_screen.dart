import 'package:flutter/material.dart';
import '../widgets/auth_widgets.dart';
import 'main_wrapper.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Lexia.png', width: 120),
              const SizedBox(height: 16),

              SizedBox(
                width: 330,
                child: Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Join Lexia today!",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        const AuthTextField(
                          label: "Your Name",
                          hint: "John Doe",
                        ),
                        const AuthTextField(
                          label: "Email",
                          hint: "parent@example.com",
                        ),
                        const AuthTextField(
                          label: "Password",
                          hint: "........",
                          isObscure: true,
                        ),
                        const AuthTextField(label: "4-Digit PIN", hint: "1234"),
                        const AuthTextField(label: "Confirm PIN", hint: "1234"),
                        const SizedBox(height: 8),
                        GradientButton(
                          text: "Create Account",
                          onPressed: () {
                            // Navigate to Dashboard
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainWrapper(),
                              ),
                            );
                          },
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Already have an account? Sign In",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
