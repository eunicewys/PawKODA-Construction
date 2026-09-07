import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// LoginScreen: The first screen the user sees.
/// Updated with official Morandi Natural Palette.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  // Morandi Palette Constants
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  // Logic to authenticate and fetch profile data
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showPawDialog("Error", "Please enter email and password.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('USERS')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'owner';
        final String name = data['displayName'] ?? 'User';

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
        _showPawDialog("Access Error", "User profile not found in database.", isError: true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Login failed.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = "Invalid email or password. Please try again.";
      }
      _showPawDialog("Login Error", errorMsg, isError: true);
    } catch (e) {
      _showPawDialog("Connection Error", "The network is slow. Please try again in a few seconds.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPawDialog(String title, String message, {required bool isError}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? _errorCoral : _lightBronze,
              size: 50,
            ),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: _darkText, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: _darkText),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? _errorCoral : _lightBronze,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Okay",
                  style: TextStyle(
                    color: isError ? Colors.white : _darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dustyOlive, // Primary structural color
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
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "PawKODA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "Pet Health & Nutrition Platform",
                  style: TextStyle(color: _powderPetal.withAlpha(200), fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Bottom section: Curved White Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back!",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkText),
                    ),
                    const Text(
                      "Sign in to manage your pet's health",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    
                    _buildField("EMAIL ADDRESS", _emailController, "hello@pawkoda.com"),
                    const SizedBox(height: 20),
                    _buildField("PASSWORD", _passwordController, "••••••••", isPass: true),
                    const SizedBox(height: 40),
                    
                    // The Sign In Button (Dusty Olive)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dustyOlive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: "Create Account",
                                style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold),
                              )
                            ],
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

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _ashGrey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass && _isObscured,
          style: TextStyle(color: _darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _ashGrey.withAlpha(150), fontSize: 14),
            fillColor: _powderPetal.withAlpha(50),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPass 
              ? IconButton(
                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: _ashGrey),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ) 
              : null,
          ),
        ),
      ],
    );
  }
}
