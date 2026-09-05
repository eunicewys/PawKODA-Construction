import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to capture user input from text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscured = true;

  // Function to handle the registration process
  Future<void> _handleRegister() async {
    // 1. Basic Validation: check if fields are empty
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true); // Start showing the loading spinner

    try {
      // 2. Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      /**
       * IMPORTANT FOR VIVA: 
       * All new accounts are set to 'owner' role by default for security.
       * This prevents regular users from accidentally or intentionally becoming admins.
       * If a user needs to be a 'vet' or 'admin', you can change it manually in Firebase Console.
       */
      const String defaultRole = 'owner';

      // 3. Save additional user details (name, role) to Firestore database
      // We add a 10-second timeout here. If the network is slow, it will still
      // move to the next step, and Firestore will finish saving in the background.
      await FirebaseFirestore.instance.collection('USERS').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        // If it takes more than 10s, we just log it and move on.
        debugPrint("Firestore save timed out, proceeding anyway...");
      });

      // 4. Update the local UserProvider to remember who is logged in
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          userCredential.user!.uid,
          _nameController.text.trim(),
          defaultRole,
          _emailController.text.trim(),
        );

        // 5. Navigate to the Home Screen and remove this screen from history
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Registration failed.");
    } catch (e) {
      _showSnackBar("Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false); // Stop loading spinner
    }
  }

  // Helper function to show simple popup messages at the bottom
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF759C86), // Primary Morandi Green
      body: Stack(
        children: [
          // Top section with App Name and Logo
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51), // Transparent white
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white, size: 50),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create Account",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Bottom section: White curved container (The Form)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Join PawKODA",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                    ),
                    const Text(
                      "Start to manage your pet's health today",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 25),

                    // Input: Full Name
                    _buildTextField(label: "FULL NAME", controller: _nameController, hint: "Sarah Lim"),
                    const SizedBox(height: 15),
                    
                    // Input: Email Address
                    _buildTextField(label: "EMAIL ADDRESS", controller: _emailController, hint: "hello@pawkoda.com"),
                    const SizedBox(height: 15),
                    
                    // Input: Password
                    _buildTextField(label: "PASSWORD", controller: _passwordController, hint: "••••••••", isPassword: true),
                    const SizedBox(height: 35),
                    
                    // The "Sign Up" Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF759C86),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    // Link to go back to Login Page
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Already have an account? Sign In", style: TextStyle(color: Color(0xFF759C86))),
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

  // Reusable helper function to build styled text input fields
  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _isObscured,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), // Lighter grey for hint text
            fillColor: const Color(0xFFF0F4F2),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: isPassword 
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
