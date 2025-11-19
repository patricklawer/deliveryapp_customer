import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'pickup_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sign up to get started",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // Name
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Full Name", Icons.person),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Email", Icons.email),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextField(
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Password", Icons.lock),
                  ),
                  const SizedBox(height: 30),

                  // Signup Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PickupScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Sign Up", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),

                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Already have an account? Login", style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
