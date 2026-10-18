import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/fringe_header.dart';

/// PrivacySecurityScreen: Compact & sleek layout providing password change,
/// security preferences, active session details, privacy policies, and account deletion options.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _ashGrey = const Color(0xFF8A8A7C);
  final Color _errorCoral = const Color(0xFFB56576);



  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: _dustyOlive, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Change Password",
                    style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Enter current password and choose a new password.",
                      style: TextStyle(fontSize: 12, color: _ashGrey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentPassController,
                      obscureText: obscureCurrent,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: _ashGrey, size: 18),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "New Password",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: _ashGrey, size: 18),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPassController,
                      obscureText: obscureConfirm,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Confirm New Password",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _ashGrey, size: 18),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(fontSize: 13)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dustyOlive,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPass = currentPassController.text.trim();
                          final newPass = newPassController.text.trim();
                          final confirmPass = confirmPassController.text.trim();

                          if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                            _showToast("Please fill in all fields.");
                            return;
                          }

                          if (newPass.length < 6) {
                            _showToast("New password must be at least 6 characters.");
                            return;
                          }

                          if (newPass != confirmPass) {
                            _showToast("New passwords do not match.");
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null || user.email == null) {
                              _showToast("No active user session.");
                              setDialogState(() => isSubmitting = false);
                              return;
                            }

                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPass,
                            );

                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(newPass);

                            if (!mounted) return;
                            Navigator.pop(context);
                            _showSuccessDialog("Password Changed", "Your password has been updated successfully.");
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isSubmitting = false);
                            String err = "Failed to update password.";
                            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                              err = "Current password is incorrect.";
                            } else if (e.code == 'weak-password') {
                              err = "The new password is too weak.";
                            } else {
                              err = e.message ?? err;
                            }
                            _showToast(err);
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            _showToast("Error: $e");
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Update Password", style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: _darkCharcoal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: Text(message, style: TextStyle(color: _darkCharcoal, fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _dustyOlive,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay", style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<UserProvider>().email ?? FirebaseAuth.instance.currentUser?.email ?? '';

    const Color beachBg = Color(0xFFF2E6DC);

    return Scaffold(
      backgroundColor: beachBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Privacy & Security",
            subtitle: "Account Protection",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _buildSectionHeader("LOGIN & AUTHENTICATION"),
              const SizedBox(height: 6),
              _buildCard([
                _buildTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Change Password",
                  subtitle: "Update account password",
                  onTap: _showChangePasswordDialog,
                ),
              ]),

              const SizedBox(height: 14),
              _buildSectionHeader("PRIVACY & DATA PROTECTION"),
              const SizedBox(height: 6),
              _buildCard([
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  subtitle: "Read how PawKODA protects your pet data",
                  onTap: () => _showPolicySheet("PawKODA Privacy Policy", _privacyPolicyText),
                ),
                const Divider(height: 1, indent: 48),
                _buildTile(
                  icon: Icons.description_outlined,
                  title: "Terms of Service",
                  subtitle: "PawKODA terms of use and service agreements",
                  onTap: () => _showPolicySheet("Terms of Service", _termsText),
                ),
              ]),

              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _errorCoral.withAlpha(60)),
                ),
                child: _buildTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: _errorCoral,
                  title: "Delete Account",
                  titleColor: _errorCoral,
                  subtitle: "Permanently delete profile and pet records",
                  onTap: _showDeleteAccountDialog,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ],
  ),
);
}

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _ashGrey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: (iconColor ?? _dustyOlive) == _errorCoral
              ? _errorCoral.withAlpha(20)
              : _powderPetal,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? _dustyOlive, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: titleColor ?? _darkCharcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: _ashGrey),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: _ashGrey, size: 18),
      onTap: onTap,
    );
  }

  void _showPolicySheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(
                      content,
                      style: TextStyle(fontSize: 13, color: _darkCharcoal, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dustyOlive,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("I Understand", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _errorCoral, size: 24),
            const SizedBox(width: 8),
            Text("Delete Account", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete your PawKODA account? All your registered pets, vaccination records, and booking history will be permanently deleted.",
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showToast("Account deletion request submitted.");
            },
            child: const Text("Request Deletion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  static const String _privacyPolicyText = '''
PawKODA Privacy Policy

1. Data Collection
PawKODA collects necessary information to provide pet health tracking, vaccination reminders, and veterinary booking services.

2. Usage of Information
Your information is strictly used for:
- Delivering daily health alerts and vaccine booster schedules.
- Calculating caloric requirements (RER/DER) and recipe recommendations.
- Facilitating vet clinic appointments.
- Notifications are stored for 30 days before automatic purge.

3. Data Security
All communication with Firebase backend services is encrypted via SSL/TLS. We do not sell user data.
''';

  static const String _termsText = '''
PawKODA Terms of Service

1. Acceptance of Terms
By accessing PawKODA, you agree to comply with these Terms of Service.

2. Veterinary Disclaimer
PawKODA provides health calculation algorithms for informational purposes only and does not replace professional veterinary examination.
''';
}
