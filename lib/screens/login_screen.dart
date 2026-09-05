import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/**
 * LoginScreen: The first screen the user sees.
 * Features a split Morandi layout (Green Top, White Curved Bottom).
 */
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Logic to authenticate and fetch profile data
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth: Sign In
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Firestore: Fetch user document to get their name and role
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('USERS')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'owner';
        final String name = data['displayName'] ?? 'User';

        // 3. Save to UserProvider and go to Home
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(
            userCredential.user!.uid,
            name,
            role,
            userCredential.user!.email ?? '',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showSnackBar("User profile not found in database.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF759C86), // Sage Green background
      body: Stack(
        children: [
          // Top section: Logo & App Name
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 70),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.pets, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("PawKODA", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const Text("Pet Health & Nutrition Platform", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Bottom section: Curved White Sheet for the Form
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    const Text("Sign in to manage your pet's health", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 30),
                    
                    _buildField("EMAIL ADDRESS", _emailController, "hello@pawkoda.com"),
                    const SizedBox(height: 20),
                    _buildField("PASSWORD", _passwordController, "••••••••", isPass: true),
                    const SizedBox(height: 40),
                    
                    // The Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF759C86), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    // Link to navigate to Registration Screen
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(color: Colors.grey),
                            children: [TextSpan(text: "Create Account", style: TextStyle(color: const Color(0xFF759C86), fontWeight: FontWeight.bold))],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable text field helper
  Widget _buildField(String label, TextEditingController controller, String hint, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            fillColor: const Color(0xFFF0F4F2),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
