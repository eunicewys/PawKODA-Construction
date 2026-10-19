import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_helper.dart';

/// VetRegisterScreen: Registration page for Veterinary Organizations.
/// Vets must fill in all details, including SSM number and proof documents/photos
/// to verify authenticity. After registration, the account status is set to 'pending'
/// until reviewed and approved by an Administrator.
class VetRegisterScreen extends StatefulWidget {
  const VetRegisterScreen({super.key});

  @override
  State<VetRegisterScreen> createState() => _VetRegisterScreenState();
}

class _VetRegisterScreenState extends State<VetRegisterScreen> {
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _ssmNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _operatingHoursController = TextEditingController(text: "09:00 AM - 07:00 PM");
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedImagePath;
  bool _isLoading = false;
  bool _isObscuredPassword = true;
  bool _isObscuredConfirm = true;

  // Colors
  final Color _coffeeBean = const Color(0xFF7F5539);
  final Color _toffeeBrown = const Color(0xFF9C6644);
  final Color _fadedCopper = const Color(0xFFB08968);
  final Color _almondCream = const Color(0xFFEDE0D4);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  Future<void> _pickProofImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      _showPawDialog("Image Picker Error", "Failed to select image: $e", isError: true);
    }
  }

  Future<void> _handleRegister() async {
    final String clinicName = _clinicNameController.text.trim();
    final String ssmNumber = _ssmNumberController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String address = _addressController.text.trim();
    final String operatingHours = _operatingHoursController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validation
    if (clinicName.isEmpty || ssmNumber.isEmpty || email.isEmpty || 
        phone.isEmpty || address.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showPawDialog("Incomplete Application", "Please fill in all required fields marked with *.", isError: true);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showPawDialog("Invalid Email", "Please enter a valid organization email address.", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showPawDialog("Password Mismatch", "The passwords entered do not match.", isError: true);
      return;
    }

    if (password.length < 6) {
      _showPawDialog("Weak Password", "Password must be at least 6 characters long.", isError: true);
      return;
    }

    if (_selectedImagePath == null) {
      _showPawDialog(
        "Proof Photo Required",
        "Please attach a photo/document of your SSM Registration or Veterinary Operating License to prove authenticity.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Convert proof image to Base64 data URL
      String? base64ProofImage;
      if (_selectedImagePath != null) {
        base64ProofImage = await ImageHelper.imageToBase64(_selectedImagePath);
      }

      // 3. Create Firebase Auth user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // 4. Save to USERS collection with role 'vet' and status 'pending'
      final Map<String, dynamic> vetUserData = {
        'uid': uid,
        'displayName': clinicName,
        'clinicName': clinicName,
        'ssmNumber': ssmNumber,
        'email': email,
        'phone': phone,
        'address': address,
        'operatingHours': operatingHours.isEmpty ? "09:00 AM - 07:00 PM" : operatingHours,
        'proofDocumentUrl': base64ProofImage ?? '',
        'role': 'vet',
        'status': 'pending', // PENDING ADMIN APPROVAL
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('USERS').doc(uid).set(vetUserData);

      // 5. Also record in CLINICS collection for prospective directory listings
      await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set({
        'id': uid,
        'name': clinicName,
        'ssmNumber': ssmNumber,
        'address': address,
        'phone': phone,
        'email': email,
        'operatingHours': operatingHours.isEmpty ? "09:00 AM - 07:00 PM" : operatingHours,
        'proofDocumentUrl': base64ProofImage ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 6. Sign out user immediately so they cannot bypass pending state
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showPawDialog(
          "Application Submitted",
          "Your Veterinary Organization registration (SSM: $ssmNumber) has been submitted successfully.\n\n"
          "Your account is currently PENDING review by a PawKODA administrator. Once verified, you will be able to log in to access the Vet Dashboard.",
          isError: false,
          onConfirm: () {
            Navigator.pop(context); // Return to VetLoginScreen
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Registration failed.";
      if (e.code == 'email-already-in-use') {
        errorMsg = "This email is already registered in the system.";
      } else if (e.code == 'weak-password') {
        errorMsg = "The password provided is too weak.";
      } else {
        errorMsg = e.message ?? "An authentication error occurred.";
      }
      _showPawDialog("Registration Error", errorMsg, isError: true);
    } catch (e) {
      _showPawDialog("Registration Error", "Failed to submit application: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPawDialog(String title, String message, {required bool isError, VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                onPressed: () {
                  Navigator.pop(context);
                  if (onConfirm != null) onConfirm();
                },
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Veterinary Registration",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Organization Account Application",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Organization Verification Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "All details will be reviewed by PawKODA Admin before account approval.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      _buildField("CLINIC / ORGANIZATION NAME", _clinicNameController, "e.g. Paw Health Veterinary Clinic"),
                      const SizedBox(height: 12),
                      _buildField("SSM REGISTRATION NUMBER", _ssmNumberController, "e.g. 202301098765 (1234567-X)"),
                      const SizedBox(height: 12),
                      _buildField("ORGANIZATION EMAIL", _emailController, "clinic@domain.com", keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildField("CONTACT PHONE NUMBER", _phoneController, "e.g. +60 12-345 6789", keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildField("CLINIC ADDRESS", _addressController, "e.g. 123 Jalan Vet, Penang", maxLines: 2),
                      const SizedBox(height: 12),
                      _buildField("OPERATING HOURS", _operatingHoursController, "e.g. 09:00 AM - 07:00 PM"),
                      const SizedBox(height: 16),

                      // SSM / License Proof Photo Picker
                      Text.rich(
                        TextSpan(
                          text: "PROOF OF AUTHENTICITY (SSM / LICENSE PHOTO)",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _fadedCopper),
                          children: const [
                            TextSpan(text: " *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickProofImage,
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: _almondCream.withAlpha(80),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedImagePath != null ? _toffeeBrown : Colors.grey[300]!,
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(_selectedImagePath!),
                                        width: double.infinity,
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 16,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                                            onPressed: _pickProofImage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: _toffeeBrown, size: 36),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tap to upload SSM Certificate or License Photo",
                                      style: TextStyle(color: _toffeeBrown, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Supports JPG, PNG (Max 10MB)",
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildField(
                        "CREATE PASSWORD",
                        _passwordController,
                        "••••••••",
                        isPass: true,
                        isObscured: _isObscuredPassword,
                        onToggle: () => setState(() => _isObscuredPassword = !_isObscuredPassword),
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        "CONFIRM PASSWORD",
                        _confirmPasswordController,
                        "••••••••",
                        isPass: true,
                        isObscured: _isObscuredConfirm,
                        onToggle: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                              : const Text("Submit Application for Admin Review", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text.rich(
                            TextSpan(
                              text: "Already registered? ",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: "Sign In as Vet",
                                  style: TextStyle(color: _toffeeBrown, fontWeight: FontWeight.bold, fontSize: 13),
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
    bool isObscured = true,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPass && isObscured,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: _darkText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _fadedCopper.withAlpha(150), fontSize: 13),
            fillColor: _almondCream.withAlpha(70),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: _fadedCopper),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
