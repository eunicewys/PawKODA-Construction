import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

/**
 * VetHomeScreen: Dashboard for Veterinarians.
 * Uses the Warm Brown/Sand Palette (Coffee/Toffee/Oak).
 */
class VetHomeScreen extends StatelessWidget {
  const VetHomeScreen({super.key});

  // Warm Brown/Sand Palette
  final Color _coffeeBean = const Color(0xFF7F5539);
  final Color _toffeeBrown = const Color(0xFF9C6644);
  final Color _fadedCopper = const Color(0xFFB08968);
  final Color _almondCream = const Color(0xFFEDE0D4);
  final Color _paleOak = const Color(0xFFE6CCB2);
  final Color _tan = const Color(0xFFDDB892);
  final Color _darkText = const Color(0xFF2D3142);

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
    final userProvider = context.watch<UserProvider>();
    final String clinicName = "PawKODA Central Clinic"; // Placeholder

    return Scaffold(
      backgroundColor: _almondCream, // Warm background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Clinic Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(clinicName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _coffeeBean)),
                            const SizedBox(width: 6),
                            Icon(Icons.verified, color: _toffeeBrown, size: 18),
                          ],
                        ),
                        Text("Subang Jaya, Selangor", style: TextStyle(color: _fadedCopper, fontSize: 13)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _handleLogout(context),
                        icon: Icon(Icons.logout_rounded, color: _coffeeBean),
                        tooltip: "Logout",
                      ),
                      CircleAvatar(
                        radius: 26, 
                        backgroundColor: _coffeeBean, 
                        child: const Icon(Icons.local_hospital, color: Colors.white, size: 24)
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Appointment Queue
              Text("Appointment Queue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              _appointmentCard("Sarah Lim", "Buddy (Dog)", "10:30 AM", "PENDING", _toffeeBrown),
              _appointmentCard("John Doe", "Kitty (Cat)", "11:15 AM", "CONFIRMED", Colors.green),
              const SizedBox(height: 32),

              // 3. Schedule Panel
              Text("Operational Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _paleOak, width: 1.5)
                ),
                child: Column(
                  children: [
                    _scheduleToggle("Accepting Bookings", true),
                    const Divider(),
                    _scheduleToggle("Emergency Service", false),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: _coffeeBean, minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Edit Availability Slots", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Clinic Manager Shortcuts
              Text("Clinic Manager", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _managerShortcut(Icons.photo_library, "Clinic Photos")),
                  const SizedBox(width: 12),
                  Expanded(child: _managerShortcut(Icons.contact_phone, "Contacts")),
                ],
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _appointmentCard(String owner, String pet, String time, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(owner, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkText)),
                  Text(pet, style: TextStyle(color: _fadedCopper, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: _fadedCopper),
              const SizedBox(width: 6),
              Text(time, style: TextStyle(color: _darkText, fontWeight: FontWeight.w500)),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text("Reject", style: TextStyle(color: Colors.grey))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {}, 
                style: ElevatedButton.styleFrom(backgroundColor: _toffeeBrown, padding: const EdgeInsets.symmetric(horizontal: 20)),
                child: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleToggle(String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _darkText, fontWeight: FontWeight.w500)),
        Switch(
          value: value, 
          onChanged: (v) {}, 
          activeThumbColor: _coffeeBean,
          activeTrackColor: _tan,
        ),
      ],
    );
  }

  Widget _managerShortcut(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _paleOak.withAlpha(100), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: _coffeeBean),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _coffeeBean)),
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
        selectedItemColor: _coffeeBean,
        unselectedItemColor: _fadedCopper,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: "Queue"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Clinic"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
