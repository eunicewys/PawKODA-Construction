import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pawkoda_fyp/providers/user_provider.dart';
import 'package:pawkoda_fyp/utils/image_helper.dart';
import 'package:pawkoda_fyp/screens/widgets/fringe_header.dart';
import 'package:pawkoda_fyp/screens/login_screen.dart';
import 'package:pawkoda_fyp/screens/nutrition/nutrition_database_screen.dart';
import 'package:pawkoda_fyp/screens/admin/breed_management_screen.dart';
import 'package:pawkoda_fyp/screens/admin/clinics_registry_screen.dart';
import 'package:pawkoda_fyp/screens/admin/past_vet_applications_screen.dart';

/// AdminHomeScreen: Dashboard for System Administrators.
/// Features a sticky wave FringeHeader, functional Bottom Navigation for Dashboard, Users, Data, and Security,
/// real-time User Role Management, and a Support Tickets / Reported Issues desk.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Professional Blue/White Palette
  final Color _yaleBlue = const Color(0xFF1B4965);
  final Color _pacificBlue = const Color(0xFF62B6CB);
  final Color _freshSky = const Color(0xFF5FA8D3);
  final Color _frozenWater = const Color(0xFFBEE9E8);
  final Color _paleSky = const Color(0xFFCAE9FF);
  final Color _darkText = const Color(0xFF2D3142);

  int _currentNavIndex = 0;
  String _searchQuery = "";
  String _searchTicketQuery = "";
  String _selectedUserRoleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _frozenWater,
      body: Column(
        children: [
          FringeHeader(
            title: _getTabHeaderTitle(),
            subtitle: "Admin Panel",
            backgroundColor: _yaleBlue,
            trailing: IconButton(
              onPressed: () => _handleLogout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
              tooltip: "Logout",
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: _buildCurrentTabView(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Logout Logic with Confirmation Dialog
  Future<void> _handleLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: _yaleBlue, size: 22),
              const SizedBox(width: 8),
              const Text("Confirm Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Are you sure you want to log out of the Admin Panel?",
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yaleBlue,
                elevation: 0,
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).clearUser();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Update Vet Approval Status in Firestore (USERS & CLINICS)
  Future<void> _updateVetStatus(String uid, String clinicName, String newStatus, {Map<String, dynamic>? fullData}) async {
    try {
      await FirebaseFirestore.instance.collection('USERS').doc(uid).update({
        'status': newStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Sync status to CLINICS collection
      await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application for '$clinicName' marked as ${newStatus.toUpperCase()}", style: const TextStyle(fontSize: 12)),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );

        if (newStatus == 'approved') {
          // Open Clinics Registry pre-filled with clinic's details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClinicsRegistryScreen(
                initialVetApplicationData: {
                  'uid': uid,
                  'clinicName': clinicName,
                  'email': fullData?['email'] ?? '',
                  'phone': fullData?['phone'] ?? '',
                  'address': fullData?['address'] ?? '',
                  'ssmNumber': fullData?['ssmNumber'] ?? '',
                  'googleMapsUrl': fullData?['googleMapsUrl'] ?? '',
                  'proofDocumentUrl': fullData?['proofDocumentUrl'] ?? '',
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e", style: const TextStyle(fontSize: 12)), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Delete Vet Application Record from Firestore
  Future<void> _deleteVetApplication(String uid, String clinicName) async {
    try {
      await FirebaseFirestore.instance.collection('USERS').doc(uid).delete();
      await FirebaseFirestore.instance.collection('CLINICS').doc(uid).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application for '$clinicName' permanently deleted.", style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete application: $e", style: const TextStyle(fontSize: 12)), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmRejectVet(String uid, String clinicName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text("Confirm Rejection", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Are you sure you want to reject the veterinary application for '$clinicName'?",
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _updateVetStatus(uid, clinicName, 'rejected');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Yes, Reject", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteVet(String uid, String clinicName) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text("Delete Application", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Are you sure you want to permanently delete the application record for '$clinicName'? This cannot be undone.",
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _deleteVetApplication(uid, clinicName);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete Record", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showFullVetDetailsDialog(String uid, Map<String, dynamic> data) {
    final String clinicName = data['clinicName'] ?? data['displayName'] ?? 'Vet Organization';
    final String ssmNumber = data['ssmNumber'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String phone = data['phone'] ?? 'N/A';
    final String address = data['address'] ?? 'N/A';
    final String websiteUrl = data['websiteUrl'] ?? '';
    final String googleMapsUrl = data['googleMapsUrl'] ?? '';
    final String proofUrl = data['proofDocumentUrl'] ?? '';
    final String status = (data['status'] ?? 'pending').toString().toLowerCase();

    Color statusColor = Colors.orange;
    String statusLabel = "PENDING REVIEW";
    if (status == 'approved') {
      statusColor = Colors.green;
      statusLabel = "APPROVED";
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = "REJECTED";
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560, maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _yaleBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Application Full Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              clinicName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withAlpha(100)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      _buildDetailRow(Icons.badge_outlined, "SSM Registration Number", ssmNumber),
                      _buildDetailRow(Icons.email_outlined, "Organization Email", email),
                      _buildDetailRow(Icons.phone_outlined, "Contact Phone Number", phone),
                      _buildDetailRow(Icons.location_on_outlined, "Clinic Address", address),
                      _buildDetailRow(
                        Icons.language_outlined,
                        "Website / Social Media Link",
                        websiteUrl.isNotEmpty ? websiteUrl : "Not provided",
                      ),
                      _buildDetailRow(
                        Icons.map_outlined,
                        "Google Maps Location Link",
                        googleMapsUrl.isNotEmpty ? googleMapsUrl : "Not provided",
                      ),
                      _buildDetailRow(Icons.fingerprint, "Account UID", uid),

                      const SizedBox(height: 10),
                      Text(
                        "PROOF OF AUTHENTICITY (SSM / LICENSE PHOTO)",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _yaleBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: proofUrl.isNotEmpty && ImageHelper.getImageProvider(proofUrl) != null
                            ? () => _showZoomablePhotoViewer(context, proofUrl, clinicName)
                            : null,
                        child: Stack(
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxHeight: 220, minHeight: 100),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: proofUrl.isNotEmpty
                                    ? (ImageHelper.getImageProvider(proofUrl) != null
                                        ? Image(image: ImageHelper.getImageProvider(proofUrl)!, fit: BoxFit.contain)
                                        : const Center(child: Text("Invalid image format", style: TextStyle(fontSize: 11))))
                                    : const Center(child: Text("No document uploaded", style: TextStyle(fontSize: 11))),
                              ),
                            ),
                            if (proofUrl.isNotEmpty && ImageHelper.getImageProvider(proofUrl) != null)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(180),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        "Tap to Zoom & View Full Size",
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Close", style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                    ),
                    const Spacer(),
                    if (status == 'rejected')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _confirmDeleteVet(uid, clinicName);
                        },
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text("Delete Application", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else ...[
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _confirmRejectVet(uid, clinicName);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Reject", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      if (status != 'approved') const SizedBox(width: 6),
                      if (status != 'approved')
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _updateVetStatus(uid, clinicName, 'approved', fullData: data);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Approve", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _yaleBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: _darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomablePhotoViewer(BuildContext context, String proofUrl, String clinicName) {
    final imageProvider = ImageHelper.getImageProvider(proofUrl);
    if (imageProvider == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 5.0,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withAlpha(200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              clinicName.isNotEmpty ? clinicName : "Proof of Authenticity",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              "SSM / License Document • Pinch or drag to zoom in/out",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(ctx),
                        tooltip: "Close",
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

  String _getTabHeaderTitle() {
    switch (_currentNavIndex) {
      case 1:
        return "USER & SUPPORT";
      case 2:
        return "Database Management";
      default:
        return "PawKODA System";
    }
  }

  Widget _buildCurrentTabView() {
    switch (_currentNavIndex) {
      case 1:
        return _buildUsersAndSupportTab();
      case 2:
        return _buildDataTab();
      default:
        return _buildDashboardTab();
    }
  }

  // TAB 0: DASHBOARD VIEW
  Widget _buildDashboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. PILLAR: VETERINARY ORGANIZATION VERIFICATION
        _buildSectionTitle("Veterinary Applications Verification"),
        const SizedBox(height: 4),
        _buildProviderVerificationSection(),
        const SizedBox(height: 20),

        // 2. PILLAR: USER ROLE WITH VIEW ALL REDIRECT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle("User Role"),
            InkWell(
              onTap: () => setState(() => _currentNavIndex = 1),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _pacificBlue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _pacificBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDashboardUserRoleSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  // TAB 1: USERS & SUPPORT TICKETS VIEW
  Widget _buildUsersAndSupportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: User Directory & Roles
        _buildSectionTitle("Registered Users Directory"),
        const SizedBox(height: 8),
        _buildFullUserDirectorySection(),
        const SizedBox(height: 24),

        // Section 2: Reported Issues & Support Desk Tickets
        _buildSupportTicketsSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  // TAB 2: DATA TAB
  Widget _buildDataTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Database Management"),
        const SizedBox(height: 12),
        _databaseCardModule(
          icon: Icons.add_business_rounded,
          title: "Clinics Registry",
          subtitle: "Penang Vet Network & Operating Details",
          color: _pacificBlue, // 62B6CB
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClinicsRegistryScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _databaseCardModule(
          icon: Icons.history_edu_rounded,
          title: "Past Veterinary Applications",
          subtitle: "Approved & Rejected Application History",
          color: _freshSky, // 5FA8D3
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PastVetApplicationsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _databaseCardModule(
          icon: Icons.no_food_rounded,
          title: "Nutrition Database",
          subtitle: "Food & Nutrient Management",
          color: _pacificBlue, // 62B6CB
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NutritionDatabaseScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _databaseCardModule(
          icon: Icons.pets_rounded,
          title: "Breeds Database",
          subtitle: "Dog & Cat Breed Management",
          color: _freshSky, // 5FA8D3
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BreedManagementScreen()),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // Dashboard User Role Box (Max 5 users, name and role only)
  Widget _buildDashboardUserRoleSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('USERS').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Error loading users: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 11)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("No registered users found.", style: TextStyle(fontSize: 11)),
            );
          }

          final docs = snapshot.data!.docs;
          final maxDocs = docs.length > 5 ? docs.sublist(0, 5) : docs;

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: maxDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 8),
            itemBuilder: (context, index) {
              final userData = maxDocs[index].data() as Map<String, dynamic>;
              final name = userData['displayName'] ?? "Unknown User";
              final role = userData['role'] ?? "owner";
              return _dashboardUserItem(name, role);
            },
          );
        },
      ),
    );
  }

  Widget _dashboardUserItem(String name, String role) {
    final validRoles = ['owner', 'vet', 'admin'];
    final currentRole = validRoles.contains(role.toLowerCase()) ? role.toLowerCase() : 'owner';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _darkText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 68,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _frozenWater,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentRole.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _yaleBlue),
            ),
          ),
        ],
      ),
    );
  }

  // Users Module Full Directory (With Search & Categorical Role Chips: All, Pet Owner, Vet, Admin)
  Widget _buildFullUserDirectorySection() {
    final roleFilters = ['All', 'Pet Owner', 'Vet', 'Admin'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Search users by name or email...",
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: _yaleBlue, size: 18),
              fillColor: _paleSky,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Categorical Role Filter Chips
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: roleFilters.length,
              itemBuilder: (context, index) {
                final roleCat = roleFilters[index];
                final isSelected = _selectedUserRoleFilter == roleCat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(roleCat),
                    selected: isSelected,
                    selectedColor: _pacificBlue,
                    backgroundColor: _paleSky,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _darkText,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? _pacificBlue : Colors.transparent,
                    ),
                    onSelected: (_) => setState(() => _selectedUserRoleFilter = roleCat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('USERS').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("Error loading database: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 11)),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(14.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("No registered users found.", style: TextStyle(fontSize: 11)),
                );
              }

              final users = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return false;

                final name = (data['displayName'] ?? "").toString().toLowerCase();
                final email = (data['email'] ?? "").toString().toLowerCase();
                final role = (data['role'] ?? "owner").toString().toLowerCase();

                final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);

                bool matchesRole = true;
                if (_selectedUserRoleFilter == 'Pet Owner') {
                  matchesRole = role == 'owner' || role == 'pet owner' || role == 'user';
                } else if (_selectedUserRoleFilter == 'Vet') {
                  matchesRole = role == 'vet';
                } else if (_selectedUserRoleFilter == 'Admin') {
                  matchesRole = role == 'admin';
                }

                return matchesSearch && matchesRole;
              }).toList();

              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("No users match your filters.", style: TextStyle(fontSize: 11)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  return _userRoleItem(
                    users[index].id,
                    userData['displayName'] ?? "Unknown User",
                    userData['email'] ?? "No email",
                    userData['role'] ?? "owner",
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("User Reported Issues"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
            ],
          ),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _searchTicketQuery = value.toLowerCase()),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Search tickets by email or issue keyword...",
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: _yaleBlue, size: 18),
                  fillColor: _paleSky,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('SUPPORT_TICKETS')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text("Error loading tickets: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red, fontSize: 11)),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(14.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No support tickets or reported issues yet.",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return false;
                    final email = (data['userEmail'] ?? data['contactEmail'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString().toLowerCase();
                    final message = (data['message'] ?? '').toString().toLowerCase();
                    return email.contains(_searchTicketQuery) ||
                        category.contains(_searchTicketQuery) ||
                        message.contains(_searchTicketQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No tickets match your search.",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final ticketId = docs[index].id;
                      final ticketData = docs[index].data() as Map<String, dynamic>;
                      return _buildTicketCard(ticketId, ticketData);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(String ticketId, Map<String, dynamic> data) {
    final String email = data['userEmail'] ?? data['contactEmail'] ?? 'No email provided';
    final String category = data['category'] ?? 'General Inquiry';
    final String message = data['message'] ?? 'No message details';
    final String status = (data['status'] ?? 'OPEN').toString().toUpperCase();
    final String userId = data['userId'] ?? 'N/A';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;

    final bool isResolved = status == 'RESOLVED';
    final Color statusColor = isResolved ? Colors.green : Colors.orange;

    String dateStr = 'Recent';
    if (createdAt != null) {
      final dt = createdAt.toDate();
      dateStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isResolved ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _yaleBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _yaleBlue),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(100)),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SelectableText(
            "Contact Email: $email",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _darkText),
          ),
          if (userId.isNotEmpty && userId != 'N/A') ...[
            const SizedBox(height: 2),
            SelectableText(
              "User ID: $userId",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 6),

          Text(
            message,
            style: TextStyle(fontSize: 12, color: _darkText, height: 1.3),
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const Spacer(),

              // Action: Toggle Resolved Status
              TextButton.icon(
                onPressed: () async {
                  final newStatus = isResolved ? 'OPEN' : 'RESOLVED';
                  await FirebaseFirestore.instance
                      .collection('SUPPORT_TICKETS')
                      .doc(ticketId)
                      .update({'status': newStatus});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ticket marked as $newStatus", style: const TextStyle(fontSize: 12))),
                    );
                  }
                },
                icon: Icon(
                  isResolved ? Icons.replay_rounded : Icons.check_circle_outline,
                  size: 14,
                  color: isResolved ? _yaleBlue : Colors.green,
                ),
                label: Text(
                  isResolved ? "Reopen" : "Mark Resolved",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isResolved ? _yaleBlue : Colors.green,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              const SizedBox(width: 8),

              // Action: Delete Ticket
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text("Delete Ticket", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: const Text("Delete this support ticket permanently?", style: TextStyle(fontSize: 13)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            Navigator.pop(context);
                            await FirebaseFirestore.instance.collection('SUPPORT_TICKETS').doc(ticketId).delete();
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "Delete Ticket",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _darkText));
  }

  Widget _buildProviderVerificationSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS')
          .where('role', isEqualTo: 'vet')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Error loading applications: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(14.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final pendingDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final status = (data?['status'] ?? 'pending').toString().toLowerCase();
          return status == 'pending';
        }).toList();

        if (pendingDocs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _paleSky),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, color: _pacificBlue, size: 28),
                const SizedBox(height: 8),
                Text(
                  "No Pending Applications",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  "New clinic registration awaiting review will appear here.",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = pendingDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _vetVerificationCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _vetVerificationCard(String uid, Map<String, dynamic> data) {
    final String clinicName = data['clinicName'] ?? data['displayName'] ?? 'Vet Organization';
    final String ssmNumber = data['ssmNumber'] ?? 'N/A';
    final String email = data['email'] ?? 'No email';
    final String phone = data['phone'] ?? 'No phone';
    final String address = data['address'] ?? 'No address';
    final String status = (data['status'] ?? 'pending').toString().toLowerCase();

    Color statusColor = Colors.orange;
    String statusLabel = "PENDING REVIEW";

    if (status == 'approved') {
      statusColor = Colors.green;
      statusLabel = "APPROVED";
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = "REJECTED";
    }

    return GestureDetector(
      onTap: () => _showFullVetDetailsDialog(uid, data),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withAlpha(80), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_hospital, color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "SSM Reg No: $ssmNumber",
                        style: TextStyle(color: _yaleBlue, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "$email | $phone",
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          address,
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // View Full Application Details Button
                ElevatedButton.icon(
                  onPressed: () => _showFullVetDetailsDialog(uid, data),
                  icon: const Icon(Icons.info_outline, size: 14),
                  label: const Text("View Full Details", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _frozenWater,
                    foregroundColor: _yaleBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                // Delete Action Control (Only for rejected applications)
                if (status == 'rejected')
                  IconButton(
                    onPressed: () => _confirmDeleteVet(uid, clinicName),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: "Delete Application Record",
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}

  Widget _userRoleItem(String uid, String name, String email, String role) {
    final validRoles = ['owner', 'vet', 'admin'];
    final currentRole = validRoles.contains(role.toLowerCase()) ? role.toLowerCase() : 'owner';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _darkText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      email,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SelectableText(
                    "UID: $uid",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 64,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _frozenWater, borderRadius: BorderRadius.circular(8)),
            child: Text(
              currentRole.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _yaleBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _databaseCardModule({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _yaleBlue,
        unselectedItemColor: _freshSky,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        iconSize: 20,
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.storage_outlined), label: "Data"),
        ],
      ),
    );
  }
}
