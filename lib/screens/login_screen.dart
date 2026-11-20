import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/connectivity_provider.dart';
import 'support_contact_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'vet_login_screen.dart';

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
  final Color _ashGrey = const Color(0xFF8A8A7C); // Slightly darker
  final Color _darkText = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  // Logic to authenticate and fetch profile data
  Future<void> _handleLogin() async {
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    if (connectivity.isOffline) {
      _showPawDialog(
        "Internet Connection Required",
        "You are currently offline. First-time login and logging in after logout require an active internet connection.",
        isError: true,
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showPawDialog("Error", "Please enter email and password.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Network timeout during login authentication."),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('USERS')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Network timeout fetching account profile."),
          );

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'owner';
        final String normStatus = (data['status'] ?? data['approvalStatus'] ?? 'pending').toString().trim().toLowerCase();
        final String name = data['displayName'] ?? 'User';
        final String? photoUrl = data['photoUrl'];

        // Enforce role separation: Vet accounts cannot log in on Pet Owner page
        if (role == 'vet') {
          await FirebaseAuth.instance.signOut();
          if (normStatus == 'pending') {
            _showPawDialog(
              "Application Pending",
              "Application still pending for review.",
              isError: true,
            );
          } else {
            _showPawDialog(
              "Role Mismatch",
              "Veterinary Organization accounts must log in via the Vet Login page.",
              isError: true,
            );
          }
          return;
        }

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(
            userCredential.user!.uid,
            name,
            role,
            userCredential.user!.email ?? '',
            photoUrl: photoUrl,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showPawDialog("Access Error", "User profile not found.", isError: true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Login failed.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = "Invalid email or password. Please try again.";
      } else {
        errorMsg = e.message ?? "An auth error occurred.";
      }
      _showPawDialog("Login Error", errorMsg, isError: true);
    } catch (e) {
      // Show the actual technical error to help us debug
      _showPawDialog("Login Error", "Technical detail: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPawDialog(String title, String message, {required bool isError}) {
    final Color mainColor = isError ? _errorCoral : _lightBronze;
    final Color bgAlphaColor = isError ? _errorCoral.withAlpha(25) : _lightBronze.withAlpha(25);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: bgAlphaColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: mainColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _darkText.withAlpha(200),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Okay",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _dustyOlive.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: _dustyOlive,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                    Text(
                      "Reset Password",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your account email address and we'll send you a password reset link.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _darkText.withAlpha(200),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: _darkText),
                      decoration: InputDecoration(
                        hintText: "hello@pawkoda.com",
                        hintStyle: TextStyle(color: _ashGrey.withAlpha(180), fontSize: 14),
                        fillColor: _powderPetal.withAlpha(50),
                        filled: true,
                        prefixIcon: Icon(Icons.email_outlined, color: _ashGrey, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                side: BorderSide(color: _ashGrey.withAlpha(120)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: isResetting ? null : () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: _darkText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dustyOlive,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: isResetting
                                  ? null
                                  : () async {
                                      final email = resetEmailController.text.trim().toLowerCase();
                                      if (email.isEmpty || !email.contains('@')) {
                                        _showPawDialog(
                                          "Invalid Email",
                                          "Please enter a valid email address.",
                                          isError: true,
                                        );
                                        return;
                                      }

                                      setDialogState(() => isResetting = true);

                                      try {
                                        debugPrint("[PasswordReset] Querying USERS collection for: $email");
                                        // 1. Query Firestore USERS collection to check if email exists
                                        final userQuery = await FirebaseFirestore.instance
                                            .collection('USERS')
                                            .where('email', isEqualTo: email)
                                            .limit(1)
                                            .get();

                                        if (userQuery.docs.isEmpty) {
                                          setDialogState(() => isResetting = false);
                                          _showPawDialog("Reset Error", "This email is not registered.", isError: true);
                                          return;
                                        }

                                        // 2. Email IS registered -> Send password reset link
                                        debugPrint("[PasswordReset] Email found in USERS collection. Sending reset link...");
                                        await FirebaseAuth.instance.setLanguageCode('en');
                                        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                        debugPrint("[PasswordReset] Reset email sent successfully.");

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          _showPawDialog(
                                            "Reset Link Sent",
                                            "A password reset link has been sent to $email.\n\nPlease check your Inbox, Spam, Junk, or Promotions folder.",
                                            isError: false,
                                          );
                                        }
                                      } on FirebaseException catch (e) {
                                        debugPrint("[PasswordReset] FirebaseException: code=${e.code}, message=${e.message}");
                                        setDialogState(() => isResetting = false);
                                        if (e.code == 'permission-denied') {
                                          _showPawDialog(
                                            "Reset Error",
                                            "Firestore security rules block email checking. Please update Firestore rules in Firebase Console to allow reading USERS collection.",
                                            isError: true,
                                          );
                                        } else {
                                          _showPawDialog("Reset Error", e.message ?? "An error occurred.", isError: true);
                                        }
                                      } catch (e) {
                                        debugPrint("[PasswordReset] Exception: $e");
                                        setDialogState(() => isResetting = false);
                                        _showPawDialog("Reset Error", "Technical detail: $e", isError: true);
                                      }
                                    },
                              child: isResetting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Send Link",
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: _dustyOlive, // Primary structural color
      body: SafeArea(
        child: Stack(
          children: [
            // Main Body Content
            Column(
              children: [
                // Top section: Logo & App Name
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          'assets/images/pawkoda_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "PawKODA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        "Pet Health & Nutrition Platform",
                        style: TextStyle(color: _powderPetal.withAlpha(200), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                // Bottom section: Curved White Sheet filling remaining height
                Expanded(
                  child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back!",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkText),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Sign in to manage your pet's health",
                              style: TextStyle(color: Color(0xFF6C6C6C), fontSize: 13), // Darker grey
                            ),
                            const SizedBox(height: 20),
                            
                            _buildField("EMAIL ADDRESS", _emailController, "hello@pawkoda.com"),
                            const SizedBox(height: 14),
                            _buildField("PASSWORD", _passwordController, "••••••••", isPass: true),
                            const SizedBox(height: 8),
                            
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 26),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _showForgotPasswordDialog,
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: _lightBronze,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            
                            // The Sign In Button (Dusty Olive)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _dustyOlive,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: "Create Account",
                                          style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold, fontSize: 13),
                                        )
                                      ],
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isKeyboardOpen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const VetLoginScreen()),
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: "Are you a Veterinary Organization? ",
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                children: [
                                  TextSpan(
                                    text: "Click Here",
                                    style: TextStyle(
                                      color: _dustyOlive,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Help Icon / Link pinned to the absolute top-right corner of the screen
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportContactScreen()),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "Help",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isPass = false, bool isRequired = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _ashGrey),
            children: isRequired
                ? [
                    const TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass && _isObscured,
          style: TextStyle(color: _darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _ashGrey.withAlpha(180), fontSize: 14), // Darker hint
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
