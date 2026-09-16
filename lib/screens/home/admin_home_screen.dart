import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

/**
 * AdminHomeScreen: Dashboard for System Administrators.
 * Features a real-time searchable User Role Management system.
 */
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
              // 1. Header: Admin Control Panel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SYSTEM OVERSEER", style: TextStyle(color: _yaleBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Text("Admin Panel", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkText)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.greenAccent.withAlpha(50), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green, width: 1)),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Colors.green),
                        SizedBox(width: 6),
                        Text("System Secure", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleLogout(context),
                    icon: Icon(Icons.logout_rounded, color: _yaleBlue),
                    tooltip: "Logout",
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. User Role Management (CONNECTED TO FIREBASE)
              Text("User Role Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Search users...",
                        prefixIcon: Icon(Icons.search, color: _yaleBlue),
                        fillColor: _paleSky,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Real-time user list from Firestore
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('USERS').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Text("Error loading users");
                        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

                        // Filter users based on search query
                        final users = snapshot.data!.docs.where((doc) {
                          final name = (doc['displayName'] ?? "").toString().toLowerCase();
                          final email = (doc['email'] ?? "").toString().toLowerCase();
                          return name.contains(_searchQuery) || email.contains(_searchQuery);
                        }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userData = users[index].data() as Map<String, dynamic>;
                            return _userRoleItem(
                              users[index].id, 
                              userData['displayName'] ?? "No Name", 
                              userData['role'] ?? "owner"
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Database & Database Control
              Text("System Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _controlModule(Icons.no_food, "Safety DB", _pacificBlue)),
                  const SizedBox(width: 12),
                  Expanded(child: _controlModule(Icons.calculate, "Formula Params", _freshSky)),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Provider Verification
              Text("Provider Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              _verificationCard("Paw Central Clinic", "3 mins ago"),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _userRoleItem(String uid, String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: _darkText)),
                Text(uid.substring(0, 8), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: _frozenWater, borderRadius: BorderRadius.circular(12)),
            child: DropdownButton<String>(
              value: role,
              underline: const SizedBox(),
              items: ['owner', 'vet', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 12, color: _yaleBlue)))).toList(),
              onChanged: (newRole) async {
                // UPDATE REAL FIREBASE DATA
                await FirebaseFirestore.instance.collection('USERS').doc(uid).update({'role': newRole});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Role updated for $name")));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlModule(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _verificationCard(String clinic, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _paleSky)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _frozenWater, shape: BoxShape.circle), child: Icon(Icons.business, color: _yaleBlue)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(clinic, style: TextStyle(fontWeight: FontWeight.bold, color: _darkText)), Text(time, style: TextStyle(color: _freshSky, fontSize: 12))])),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: _yaleBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Verify", style: TextStyle(fontSize: 11, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _yaleBlue,
        unselectedItemColor: _freshSky,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: "Console"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.storage_outlined), label: "Data"),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), label: "Security"),
        ],
      ),
    );
  }
}
