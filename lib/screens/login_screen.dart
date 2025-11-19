import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'pickup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Login to continue your journey",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

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

                  // Login Button
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
                    child: const Text("Login", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),

                  // Signup link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70)),
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
