import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'vet_register_screen.dart';

/// VetLoginScreen: Dedicated login portal for Veterinary Organizations.
/// Completely separated from the Pet Owner login flow.
class VetLoginScreen extends StatefulWidget {
  const VetLoginScreen({super.key});

  @override
  State<VetLoginScreen> createState() => _VetLoginScreenState();
}

class _VetLoginScreenState extends State<VetLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  // Warm Coffee / Toffee Palette for Vet Module
  final Color _coffeeBean = const Color(0xFF7F5539);
  final Color _toffeeBrown = const Color(0xFF9C6644);
  final Color _fadedCopper = const Color(0xFFB08968);
  final Color _almondCream = const Color(0xFFEDE0D4);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  Future<void> _handleVetLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showPawDialog("Error", "Please enter clinic email and password.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate credentials
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      // 2. Fetch user profile from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('USERS')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showPawDialog("Access Denied", "Veterinary organization profile not found in database.", isError: true);
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final String role = data['role'] ?? 'owner';
      final String status = data['status'] ?? data['approvalStatus'] ?? 'pending';
      final String name = data['displayName'] ?? data['clinicName'] ?? 'Veterinary Clinic';
      final String? photoUrl = data['photoUrl'];

      // 3. ENFORCE ROLE SEPARATION: Must be 'vet' role
      if (role != 'vet') {
        await FirebaseAuth.instance.signOut();
        _showPawDialog(
          "Role Mismatch",
          "This account is not registered as a Veterinary Organization. Please use the Pet Owner login page.",
          isError: true,
        );
        return;
      }

      // 4. ENFORCE ADMIN APPROVAL: Must be approved by admin
      if (status == 'pending') {
        await FirebaseAuth.instance.signOut();
        _showPawDialog(
          "Account Pending Approval",
          "Your veterinary organization account is currently pending admin review and approval.\n\n"
          "You will be able to log in once an administrator verifies your SSM and credentials.",
          isError: true,
        );
        return;
      } else if (status == 'rejected') {
        await FirebaseAuth.instance.signOut();
        _showPawDialog(
          "Application Rejected",
          "Your veterinary organization account application was not approved by the administrator.\n\n"
          "Please contact PawKODA support if you believe this is an error.",
          isError: true,
        );
        return;
      } else if (status != 'approved') {
        await FirebaseAuth.instance.signOut();
        _showPawDialog("Access Restricted", "Account status ($status) does not allow login.", isError: true);
        return;
      }

      // 5. Approved Vet Login Success
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          uid,
          name,
          'vet',
          userCredential.user!.email ?? '',
          photoUrl: photoUrl,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Login failed.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = "Invalid email or password. Please try again.";
      } else {
        errorMsg = e.message ?? "An authentication error occurred.";
      }
      _showPawDialog("Login Error", errorMsg, isError: true);
    } catch (e) {
      _showPawDialog("Login Error", "Technical detail: $e", isError: true);
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
              color: isError ? _errorCoral : _toffeeBrown,
              size: 50,
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: _darkText, fontSize: 14),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? _errorCoral : _coffeeBean,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Okay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: _coffeeBean,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Vet Branding Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.local_hospital, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "PawKODA VET",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Veterinary Organization Portal",
                    style: TextStyle(color: _almondCream.withAlpha(220), fontSize: 13),
                  ),
                ],
              ),
            ),

            // Bottom Section: Curved Card Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Veterinary Sign In",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sign in to manage your clinic appointments & operations",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      _buildField("ORGANIZATION EMAIL", _emailController, "clinic@vet.com", icon: Icons.email_outlined),
                      const SizedBox(height: 14),
                      _buildField("PASSWORD", _passwordController, "••••••••", isPass: true, icon: Icons.lock_outline),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVetLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _coffeeBean,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Sign In as Vet Clinic", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Register Link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VetRegisterScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: "New Veterinary Organization? ",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: "Register Here",
                                  style: TextStyle(
                                    color: _toffeeBrown,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Switch back to Pet Owner Login
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: "Not a Veterinary Organization? ",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: "Go to Pet Owner Login",
                                  style: TextStyle(
                                    color: _coffeeBean,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isPass = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _fadedCopper),
            children: const [
              TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass && _isObscured,
          style: TextStyle(color: _darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _fadedCopper.withAlpha(180), fontSize: 14),
            fillColor: _almondCream.withAlpha(80),
            filled: true,
            prefixIcon: icon != null ? Icon(icon, color: _fadedCopper, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: _fadedCopper),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
