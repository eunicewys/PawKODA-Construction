import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

/**
 * RegisterScreen: Handles new user registration.
 */
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Input controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  // Logic to register and create database entry
  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Authentication: Create user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Firestore: Automatically create the USER document
      // We use hardcoded 'owner' as the default role for security
      const String defaultRole = 'owner';
      
      await FirebaseFirestore.instance.collection('USERS').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update UserProvider and navigate to Home
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          userCredential.user!.uid,
          _nameController.text.trim(),
          defaultRole,
          _emailController.text.trim(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
                const SizedBox(height: 50),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.pets, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 15),
                const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Bottom section: Curved White Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              padding: const EdgeInsets.all(30),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildField("FULL NAME", _nameController, "Sarah Lim"),
                    const SizedBox(height: 15),
                    _buildField("EMAIL ADDRESS", _emailController, "hello@pawkoda.com"),
                    const SizedBox(height: 15),
                    _buildField("PASSWORD", _passwordController, "••••••••", isPass: true),
                    const SizedBox(height: 35),
                    
                    // The Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF759C86), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    // Text link to Login
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Already have an account? Sign In", style: TextStyle(color: Color(0xFF759C86)))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
