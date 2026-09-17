import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

/// AdminHomeScreen: Dashboard for System Administrators.
/// Features a real-time searchable User Role Management system.
/// Simplified and professionally focused on Management pillars.
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
                              fontSize: 15, // Increased size
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                      Text("Admin Panel",
                          style: TextStyle(
                              fontSize: 27, // Increased size (+3pt)
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

              // 3. PILLAR: USER MANAGEMENT
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
                    // StreamBuilder with better error handling and null safety
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

                        // Filter users safely
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

              // 4. PILLAR: DATABASE MANAGEMENT
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
              const SizedBox(height: 32),

              // 5. PROVIDER VERIFICATION (Security Pillar Extension)
              _buildSectionTitle("Provider Verification"),
              const SizedBox(height: 12),
              _verificationCard("Paw Central Clinic", "Request: 3 mins ago"),
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
            fontSize: 21, // Increased size (+3pt)
            fontWeight: FontWeight.bold,
            color: _darkText));
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
                        fontSize: 18, // Increased size
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

  Widget _verificationCard(String clinic, String time) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _paleSky)),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _frozenWater, shape: BoxShape.circle),
              child: Icon(Icons.business, color: _yaleBlue, size: 24)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(clinic,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: _darkText)),
                Text(time, style: TextStyle(color: _freshSky, fontSize: 13))
              ])),
          ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: _yaleBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text("Verify",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))),
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
