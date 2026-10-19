import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/image_helper.dart';
import '../login_screen.dart';

/// AdminHomeScreen: Dashboard for System Administrators.
/// Features a real-time searchable User Role Management system and
/// a Veterinary Organization Application Verification pipeline.
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

  String _searchQuery = "";

  // Logout Logic
  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Update Vet Approval Status in Firestore (USERS & CLINICS)
  Future<void> _updateVetStatus(String uid, String clinicName, String newStatus) async {
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
            content: Text("Application for '$clinicName' marked as ${newStatus.toUpperCase()}"),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showProofPhotoDialog(String clinicName, String ssmNumber, String proofUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clinicName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "SSM Reg No: $ssmNumber",
                style: TextStyle(fontSize: 13, color: _yaleBlue, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: proofUrl.isNotEmpty
                        ? (ImageHelper.getImageProvider(proofUrl) != null
                            ? Image(image: ImageHelper.getImageProvider(proofUrl)!, fit: BoxFit.contain)
                            : const Center(child: Text("Invalid image format")))
                        : const Center(child: Text("No document uploaded")),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _yaleBlue),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _frozenWater, // Cool professional background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER: Branding & Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PawKODA System",
                          style: TextStyle(
                              color: _yaleBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                      Text("Admin Panel",
                          style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: _darkText)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _handleLogout(context),
                    icon: Icon(Icons.logout_rounded, color: _yaleBlue, size: 28),
                    tooltip: "Logout",
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. PILLAR: SECURITY MANAGEMENT
              _buildSectionTitle("Security Management"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colors.green),
                    SizedBox(width: 10),
                    Text("System Secure: Encrypted Connection Active",
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. PILLAR: VETERINARY ORGANIZATION VERIFICATION
              _buildSectionTitle("Veterinary Applications Verification"),
              const SizedBox(height: 12),
              _buildProviderVerificationSection(),
              const SizedBox(height: 32),

              // 4. PILLAR: USER ROLE MANAGEMENT
              _buildSectionTitle("User Role Management"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(10), blurRadius: 10)
                    ]),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Search users by name or email...",
                        prefixIcon: Icon(Icons.search, color: _yaleBlue),
                        fillColor: _paleSky,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('USERS')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("Error loading database: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red)),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No registered users found."),
                          );
                        }

                        final users = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data == null) return false;
                          
                          final name = (data['displayName'] ?? "").toString().toLowerCase();
                          final email = (data['email'] ?? "").toString().toLowerCase();
                          return name.contains(_searchQuery) || email.contains(_searchQuery);
                        }).toList();

                        if (users.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No users match your search."),
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
                              userData['role'] ?? "owner",
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 5. PILLAR: DATABASE MANAGEMENT
              _buildSectionTitle("Database Management"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _controlModule(
                          Icons.no_food, "Nutrition DB", _pacificBlue)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _controlModule(
                          Icons.analytics_outlined, "Formula Params", _freshSky)),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 21,
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
            padding: const EdgeInsets.all(12.0),
            child: Text("Error loading applications: ${snapshot.error}",
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _paleSky),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user_outlined, color: _pacificBlue, size: 36),
                const SizedBox(height: 8),
                Text(
                  "No Veterinary Organization Applications Yet",
                  style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  "New clinic registrations will appear here for SSM verification.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final vetDocs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vetDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = vetDocs[index];
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
    final String proofUrl = data['proofDocumentUrl'] ?? '';

    Color statusColor = Colors.orange;
    String statusLabel = "PENDING REVIEW";

    if (status == 'approved') {
      statusColor = Colors.green;
      statusLabel = "APPROVED";
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = "REJECTED";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_hospital, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _darkText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "SSM Reg No: $ssmNumber",
                      style: TextStyle(color: _yaleBlue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$email | $phone",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (address.isNotEmpty)
                      Text(
                        address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(100)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            children: [
              // View Proof Document Thumbnail / Button
              ElevatedButton.icon(
                onPressed: () => _showProofPhotoDialog(clinicName, ssmNumber, proofUrl),
                icon: const Icon(Icons.document_scanner_outlined, size: 16),
                label: const Text("View Proof Photo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _frozenWater,
                  foregroundColor: _yaleBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const Spacer(),

              // Action Buttons: Approve / Reject
              if (status != 'approved')
                ElevatedButton(
                  onPressed: () => _updateVetStatus(uid, clinicName, 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),

              if (status != 'approved') const SizedBox(width: 8),

              if (status != 'rejected')
                OutlinedButton(
                  onPressed: () => _updateVetStatus(uid, clinicName, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Reject", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userRoleItem(String uid, String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _darkText)),
                Text("UID: ${uid.substring(0, 8)}...",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: _frozenWater, borderRadius: BorderRadius.circular(12)),
            child: DropdownButton<String>(
              value: role,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: _yaleBlue),
              items: ['owner', 'vet', 'admin']
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _yaleBlue))))
                  .toList(),
              onChanged: (newRole) async {
                if (newRole != null) {
                  await FirebaseFirestore.instance
                      .collection('USERS')
                      .doc(uid)
                      .update({'role': newRole});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Role updated to $newRole for $name")));
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlModule(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _yaleBlue,
        unselectedItemColor: _freshSky,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.storage_outlined), label: "Data"),
          BottomNavigationBarItem(
              icon: Icon(Icons.security_outlined), label: "Security"),
        ],
      ),
    );
  }
}
