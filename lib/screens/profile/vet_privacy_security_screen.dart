import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/fringe_header.dart';

/// VetPrivacySecurityScreen: Dedicated Privacy, Security & Terms of Service screen
/// tailored specifically for Veterinary Organizations using the Warm Coffee/Toffee theme.
class VetPrivacySecurityScreen extends StatefulWidget {
  const VetPrivacySecurityScreen({super.key});

  @override
  State<VetPrivacySecurityScreen> createState() => _VetPrivacySecurityScreenState();
}

class _VetPrivacySecurityScreenState extends State<VetPrivacySecurityScreen> {
  // Warm Coffee / Toffee Palette for Vet Module
  final Color _coffeeBean = const Color(0xFF7F5539);
  final Color _toffeeBrown = const Color(0xFF9C6644);
  final Color _fadedCopper = const Color(0xFFB08968);
  final Color _almondCream = const Color(0xFFEDE0D4);
  final Color _paleOak = const Color(0xFFE6CCB2);
  final Color _darkText = const Color(0xFF2D3142);
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
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: _coffeeBean, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Change Vet Password",
                    style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Enter your current password and set a new password for your veterinary organization account.",
                      style: TextStyle(fontSize: 12, color: _fadedCopper),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: currentPassController,
                      obscureText: obscureCurrent,
                      style: TextStyle(fontSize: 13, color: _darkText),
                      decoration: InputDecoration(
                        labelText: "Current Password *",
                        labelStyle: TextStyle(color: _fadedCopper, fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: _fadedCopper, size: 18),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      style: TextStyle(fontSize: 13, color: _darkText),
                      decoration: InputDecoration(
                        labelText: "New Password *",
                        labelStyle: TextStyle(color: _fadedCopper, fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: _fadedCopper, size: 18),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPassController,
                      obscureText: obscureConfirm,
                      style: TextStyle(fontSize: 13, color: _darkText),
                      decoration: InputDecoration(
                        labelText: "Confirm New Password *",
                        labelStyle: TextStyle(color: _fadedCopper, fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _fadedCopper, size: 18),
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
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _coffeeBean,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPass = currentPassController.text.trim();
                          final newPass = newPassController.text.trim();
                          final confirmPass = confirmPassController.text.trim();

                          if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                            _showToast("Please fill in all required password fields.");
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
                          final nav = Navigator.of(dialogCtx);

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

                            nav.pop();
                            if (mounted) {
                              _showSuccessDialog("Password Changed", "Your veterinary organization account password has been updated successfully.");
                            }
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
                      : const Text("Update Password", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPolicySheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _coffeeBean.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.gavel_rounded, color: _coffeeBean, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _coffeeBean),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: _coffeeBean),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  content,
                  style: TextStyle(fontSize: 13, color: _darkText, height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _coffeeBean,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("I Understand & Agree", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _errorCoral, size: 24),
            const SizedBox(width: 8),
            Text("Request Deactivation", style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "Deactivating your Veterinary Organization account will remove your clinic directory listing and appointment queue from PawKODA. \n\n"
          "Please contact PawKODA Administrator at support@pawkoda.com for formal verification and organization account deactivation.",
          style: TextStyle(fontSize: 13, color: _darkText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Contact Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: _coffeeBean,
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
            Text(title, style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: Text(message, style: TextStyle(color: _darkText, fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _coffeeBean,
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
    return Scaffold(
      backgroundColor: _almondCream,
      body: Column(
        children: [
          FringeHeader(
            title: "Vet Privacy & Service",
            subtitle: "Organization Terms & Policies",
            backgroundColor: _coffeeBean,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("LOGIN & VET CREDENTIALS"),
                  const SizedBox(height: 6),
                  _buildCard([
                    _buildTile(
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Update veterinary organization login password",
                      onTap: _showChangePasswordDialog,
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _buildSectionHeader("VETERINARY PRIVACY & SERVICE POLICIES"),
                  const SizedBox(height: 6),
                  _buildCard([
                    _buildTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      subtitle: "SSM verification & patient data protection policies",
                      onTap: () => _showPolicySheet("Privacy Policy", _vetPrivacyPolicyText),
                    ),
                    const Divider(height: 1, indent: 48),
                    _buildTile(
                      icon: Icons.description_outlined,
                      title: "Terms of Service",
                      subtitle: "Clinic portal operating rules & appointment guidelines",
                      onTap: () => _showPolicySheet("Terms of Service", _vetTermsOfServiceText),
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _buildSectionHeader("ORGANIZATION ACCOUNT MANAGEMENT"),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _errorCoral.withAlpha(80)),
                    ),
                    child: _buildTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: _errorCoral,
                      title: "Request Account Deactivation",
                      titleColor: _errorCoral,
                      subtitle: "Formally request clinic deactivation from PawKODA",
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
          color: _fadedCopper,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _paleOak),
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? _coffeeBean).withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? _coffeeBean, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: titleColor ?? _darkText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: _fadedCopper),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _fadedCopper),
    );
  }

  static const String _vetPrivacyPolicyText = """
PAWKODA VETERINARY PRIVACY POLICY
Effective Date: January 2025

1. OVERVIEW & SCOPE
This Veterinary Privacy Policy applies exclusively to registered Veterinary Clinics, Hospitals, Practitioners, and Veterinary Organizations operating within PawKODA ("Platform"). PawKODA is committed to protecting the confidential professional information of veterinary entities and pet patient data in accordance with the Malaysian Personal Data Protection Act 2010 (PDPA) and regulations established by the Malaysian Veterinary Council (MVC).

2. COLLECTION OF VETERINARY ORGANIZATION DATA
When applying for or operating a Veterinary Account, PawKODA collects:
• Organization Details: Clinic/Hospital Name, SSM Registration Number, Physical Address, Contact Phone Number, and Official Email.
• Verification Documentation: Photos/Documents of SSM Certificates, Veterinary Operating Licenses, and Practitioner Credentials.
• Operating Details: Weekly Operating Hours, Daily Session Breaks, Offered Medical Services, and Doctor/Staff Availability.
• Appointment Records: Patient appointment requests, booking statuses, consultation notes, and owner preference details.

3. SSM & PROOF DOCUMENTATION CONFIDENTIALITY
• SSM Registration Certificates and Operating Licenses uploaded during registration are stored in encrypted, restricted storage accessible solely by PawKODA System Administrators for verification purposes.
• Proof documents are NEVER disclosed publicly, shared with third parties, or displayed to pet owner users.

4. USE OF VETERINARY DATA
PawKODA utilizes registered veterinary information strictly to:
• Verify the authenticity and operational status of veterinary organizations.
• Populate official Penang Vet Clinic directory listings (Name, Address, Phone, Operating Hours, Offered Services, and Navigation Links).
• Facilitate appointment scheduling, booking confirmations, and push notification alerts between pet owners and clinics.

5. PATIENT & MEDICAL RECORD PRIVACY
• Booking information submitted by pet owners (e.g., Pet Name, Species, Symptoms, and Preferred Vet) is shared exclusively with the designated clinic.
• Clinics are responsible for maintaining patient confidentiality in compliance with MVC ethical codes.
""";

  static const String _vetTermsOfServiceText = """
PAWKODA VETERINARY TERMS OF SERVICE
Effective Date: January 2025

1. ACCEPTANCE OF TERMS
By registering and operating a Veterinary Organization Account on PawKODA ("Platform"), your clinic or medical facility agrees to comply with these Veterinary Terms of Service.

2. ELIGIBILITY & REGISTRATION REQUIREMENTS
• Veterinary Organizations must possess valid SSM Registration and recognized Veterinary Licenses in Malaysia.
• All account applications are subject to mandatory review and approval by PawKODA Administrators before access is granted.
• PawKODA reserves the right to reject or revoke clinic access if credentials are invalid, expired, or fraudulent.

3. CLINIC RESPONSIBILITIES & OPERATIONAL ACCURACY
• Operating Hours & Schedule: Clinics agree to maintain accurate operating hours and break times. Updates can be configured weekly every Saturday for the coming week (Sunday–Saturday).
• Service Offerings: Clinics are responsible for ensuring listed medical services (e.g., Surgery, Vaccination, Consultation) accurately reflect available facilities and qualified personnel.
• Staff Availability: Clinics must manage staff and doctor availability to prevent double-booking or unfulfilled appointments.

4. APPOINTMENT MANAGEMENT
• Response Obligations: Clinics agree to promptly review, accept, or reject incoming appointment requests from pet owners.
• Cancellations: In the event an accepted appointment cannot be fulfilled due to emergencies, the clinic must notify the pet owner through the Platform or provided contact details.

5. INTELLECTUAL PROPERTY & LISTINGS
• Clinics grant PawKODA a non-exclusive license to display clinic branding, address, phone number, and location links for directory and booking purposes.

6. GOVERNING LAW
These Terms are governed by the laws of Malaysia. Any disputes shall be subject to the exclusive jurisdiction of the courts in Penang, Malaysia.
""";
}
