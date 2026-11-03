import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/image_helper.dart';
import '../widgets/fringe_header.dart';
import '../widgets/offline_banner.dart';

/// EditProfileScreen: Enables users to update their Display Name (User Name)
/// and Profile Picture with instant live preview and Firestore/Provider synchronization.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _darkBronze = const Color(0xFF985B3E);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _ashGrey = const Color(0xFF8A8A7C);

  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  File? _newImageFile;
  String? _currentPhotoUrl;
  bool _isPhotoRemoved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final up = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: up.displayName ?? '');
    _currentPhotoUrl = up.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _newImageFile = File(picked.path);
          _isPhotoRemoved = false;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Error selecting image: $e")),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Choose Profile Photo",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkCharcoal,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _powderPetal, shape: BoxShape.circle),
                    child: Icon(Icons.photo_library_rounded, color: _dustyOlive),
                  ),
                  title: const Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _powderPetal, shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_rounded, color: _dustyOlive),
                  ),
                  title: const Text("Take a Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_newImageFile != null || (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty && !_isPhotoRemoved))
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withAlpha(30), shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: const Text("Remove Photo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _newImageFile = null;
                        _isPhotoRemoved = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    if (connectivity.isOffline) {
      ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Updating profile information");
      return;
    }

    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid user name.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uid = userProvider.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No active user logged in.")),
        );
        setState(() => _isSaving = false);
        return;
      }

      String? finalPhotoUrl;

      if (_isPhotoRemoved) {
        finalPhotoUrl = null;
      } else if (_newImageFile != null) {
        // Convert newly picked local image file to base64
        finalPhotoUrl = await ImageHelper.imageToBase64(_newImageFile!.path);
      } else {
        finalPhotoUrl = _currentPhotoUrl;
      }

      // 1. Update Firestore USERS document
      await FirebaseFirestore.instance.collection('USERS').doc(uid).set({
        'displayName': newName,
        'photoUrl': finalPhotoUrl,
      }, SetOptions(merge: true));

      // 2. Update FirebaseAuth user profile
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(newName);
        if (finalPhotoUrl != null && finalPhotoUrl.startsWith('http')) {
          await firebaseUser.updatePhotoURL(finalPhotoUrl);
        }
      }

      // 3. Update global UserProvider memory
      userProvider.updateProfile(
        name: newName,
        photoUrl: finalPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text("Profile updated successfully!"),
              ],
            ),
            backgroundColor: _dustyOlive,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    const Color beachBg = Color(0xFFE6CCB2);

    ImageProvider? avatarProvider;
    if (_newImageFile != null) {
      avatarProvider = FileImage(_newImageFile!);
    } else if (!_isPhotoRemoved && _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      avatarProvider = ImageHelper.getImageProvider(_currentPhotoUrl);
    }

    return Scaffold(
      backgroundColor: beachBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Edit Profile",
            subtitle: "Display Name & Photo",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
                  const SizedBox(height: 10),

                  // Profile Picture Avatar with Edit Overlay
                  GestureDetector(
                    onTap: _showImagePickerSheet,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: _powderPetal,
                            backgroundImage: avatarProvider,
                            child: avatarProvider == null
                                ? Text(
                                    userProvider.displayName?.isNotEmpty == true
                                        ? userProvider.displayName!.substring(0, 1).toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: _dustyOlive,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _dustyOlive,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showImagePickerSheet,
                    icon: Icon(Icons.edit_rounded, size: 16, color: _darkBronze),
                    label: Text(
                      "Change Photo",
                      style: TextStyle(
                        color: _darkBronze,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PERSONAL DETAILS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _ashGrey,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Display Name Input Field
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Display Name *",
                            prefixIcon: Icon(Icons.person_outline_rounded, color: _dustyOlive),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: _dustyOlive, width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Email Field (Readonly)
                        TextField(
                          controller: TextEditingController(text: userProvider.email ?? ''),
                          readOnly: true,
                          style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: Icon(Icons.email_outlined, color: _ashGrey, size: 20),
                            suffixIcon: Icon(Icons.lock_outline_rounded, color: _ashGrey, size: 16),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            fillColor: const Color(0xFFF7F7F7),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Account Profile Badge
                        Row(
                          children: [
                            Text(
                              "Account Profile: ",
                              style: TextStyle(fontSize: 13, color: _ashGrey, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _powderPetal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                userProvider.role?.toLowerCase() == 'owner'
                                    ? "PET OWNER"
                                    : (userProvider.role ?? 'owner').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _dustyOlive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dustyOlive,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Save Profile Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
