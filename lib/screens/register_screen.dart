import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

/// RegisterScreen: Handles new user registration.
/// Updated with official Morandi Natural Palette.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscuredCreate = true;
  bool _isObscuredConfirm = true;

  //validate for error
  bool _emailError = false;
  bool _passwordError = false;

  //colour
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _ashGrey = const Color(0xFF8A8A7C); // Slightly darker
  final Color _darkText = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  Future<void> _handleRegister() async {
    // Reset error states before starting validation
    setState(() {
      _emailError = false;
      _passwordError = false;
    });

    // 1. Basic Validation: Check if fields are empty
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showPawDialog("Error", "Please fill in all fields.", isError: true);
      return;
    }

    // 2. Email Format Validation
    final String email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = true);
      _showPawDialog(
        "Registration Error", 
        "Please use a valid email address.", 
        isError: true
      );
      return;
    }

    // 3. Password Matching Validation
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = true);
      _showPawDialog("Password Mismatch", "The passwords do not match.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      const String defaultRole = 'owner';
      
      await FirebaseFirestore.instance.collection('USERS').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

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
      String errorMsg = "Registration failed.";
      if (e.code == 'email-already-in-use') {
        errorMsg = "This email is already in use.";
      } else if (e.code == 'weak-password') {
        errorMsg = "The password provided is too weak.";
      }
      _showPawDialog("Registration Error", errorMsg, isError: true);
    } catch (e) {
      // Show real error
      _showPawDialog("Access Error", "Database denied: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPawDialog(String title, String message, {required bool isError, VoidCallback? onConfirm}) {
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
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (onConfirm != null) onConfirm();
                },
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
      backgroundColor: _dustyOlive,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white, size: 48),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Join PawKODA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkText)),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Start to manage your pet's health today", style: TextStyle(color: Color(0xFF6C6C6C), fontSize: 13)), // Darker grey
                    ),
                    const SizedBox(height: 20),
                    _buildField("FULL NAME", _nameController, "Sarah Lim"),
                    const SizedBox(height: 12),
                    _buildField(
                      "EMAIL ADDRESS", 
                      _emailController, 
                      "hello@pawkoda.com",
                      hasError: _emailError,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      "CREATE PASSWORD", 
                      _passwordController, 
                      "••••••••", 
                      isPass: true,
                      isObscured: _isObscuredCreate,
                      onToggle: () => setState(() => _isObscuredCreate = !_isObscuredCreate),
                      hasError: _passwordError,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      "RE-CONFIRM PASSWORD", 
                      _confirmPasswordController, 
                      "••••••••", 
                      isPass: true,
                      isObscured: _isObscuredConfirm,
                      onToggle: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
                      hasError: _passwordError,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dustyOlive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            style: const TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold),
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
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isPass = false, bool isObscured = true, VoidCallback? onToggle, bool hasError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _ashGrey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass && isObscured,
          style: TextStyle(color: _darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _ashGrey.withAlpha(180), fontSize: 14), // Darker hint
            fillColor: _powderPetal.withAlpha(50),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError ? const BorderSide(color: Color(0xFFB56576), width: 1.5) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError ? const BorderSide(color: Color(0xFFB56576), width: 1.5) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFB56576) : _dustyOlive, 
                width: 1.5
              ),
            ),
            suffixIcon: isPass 
              ? IconButton(
                  icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: _ashGrey),
                  onPressed: onToggle,
                ) 
              : null,
          ),
        ),
      ],
    );
  }
}
