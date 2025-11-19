import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/home_bg.jpg', // 📷 Replace with your actual image path
              fit: BoxFit.cover,
            ),
          ),
          // Overlay content
          Container(
            color: Colors.black.withOpacity(0.5), // dark overlay for contrast
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome to Delivery App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(180, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size(180, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
