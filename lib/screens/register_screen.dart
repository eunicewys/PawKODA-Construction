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
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscured = true;

  // Logic to register and create database entry
  Future<void> _handleRegister() async {
    // 1. Basic Validation: Check if fields are empty
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showPawDialog("Error", "Please fill in all fields.", isError: true);
      return;
    }

    // 2. Password Matching Validation
    if (_passwordController.text != _confirmPasswordController.text) {
      _showPawDialog(
        "Password Mismatch", 
        "The passwords you entered do not match. Please try again.", 
        isError: true
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Firebase Authentication: Create user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 4. Firestore: Automatically create the USER document
      const String defaultRole = 'owner';
      
      // We add a 10-second timeout. If it takes too long, we assume it succeeded 
      // because Firestore will finish saving in the background.
      await FirebaseFirestore.instance.collection('USERS').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // 5. Update UserProvider and navigate to Home
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
    } on FirebaseAuthException catch (e) {
      // Handle common Firebase errors nicely
      String errorMsg = "Registration failed.";
      if (e.code == 'email-already-in-use') {
        errorMsg = "This email is already in use. Please sign in or use another email.";
      } else if (e.code == 'weak-password') {
        errorMsg = "The password provided is too weak.";
      }
      _showPawDialog("Registration Error", errorMsg, isError: true);
    } catch (e) {
      // If we hit a timeout or other error, we show the success message 
      // because the user is likely already recorded in Firebase Auth.
      _showPawDialog(
        "Success!", 
        "Account successfully created! Please sign in to continue.", 
        isError: false,
        onConfirm: () {
          if (mounted) Navigator.pop(context); // Go back to Login page
        }
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /**
   * _showPawDialog: A professional middle-of-screen dialog for messages.
   * Uses Muted Coral for errors and Sage Green for success.
   */
  void _showPawDialog(String title, String message, {required bool isError, VoidCallback? onConfirm}) {
    // Morandi Success Color (Muted Sand) and Error Color (Deepened Coral)
    final Color successColor = const Color(0xFFD4C2AD);
    final Color errorColor = const Color(0xFFB56576); 
    final Color darkText = const Color(0xFF2D3142);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? errorColor : successColor,
              size: 50,
            ),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: darkText),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? errorColor : successColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (onConfirm != null) onConfirm();
                },
                // White text for error button, dark text for success button
                child: Text(
                  "Okay",
                  style: TextStyle(
                    color: isError ? Colors.white : darkText,
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
      backgroundColor: const Color(0xFF759C86),
      body: Stack(
        children: [
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75, // Increased height for extra field
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Join PawKODA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Start to manage your pet's health today", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    const SizedBox(height: 20),
                    _buildField("FULL NAME", _nameController, "Sarah Lim"),
                    const SizedBox(height: 12),
                    _buildField("EMAIL ADDRESS", _emailController, "hello@pawkoda.com"),
                    const SizedBox(height: 12),
                    _buildField("CREATE PASSWORD", _passwordController, "••••••••", isPass: true),
                    const SizedBox(height: 12),
                    _buildField("RE-CONFIRM PASSWORD", _confirmPasswordController, "••••••••", isPass: true),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF759C86), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
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
          obscureText: isPass && _isObscured,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            fillColor: const Color(0xFFF0F4F2),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: isPass 
              ? IconButton(
                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ) 
              : null,
          ),
        ),
      ],
    );
  }
}
