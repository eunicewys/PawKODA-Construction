import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

/**
 * UserHomeScreen: Dashboard for Pet Owners.
 * Uses the Morandi Nature Palette (Green/Bronze/Sand).
 */
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  // Morandi Nature Palette
  final Color _sageGreen = const Color(0xFF759C86);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _ashGrey = const Color(0xFFB7B7A4);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 18) return "Good afternoon,";
    return "Good evening,";
  }

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
    final String userName = userProvider.displayName ?? 'Friend';

    return Scaffold(
      backgroundColor: _powderPetal, // Soft background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Greeting & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getGreeting(), style: TextStyle(color: _ashGrey, fontSize: 14)),
                      Text("$userName 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _handleLogout(context),
                        icon: Icon(Icons.logout_rounded, color: _dustyOlive),
                        tooltip: "Logout",
                      ),
                      CircleAvatar(
                        radius: 26, 
                        backgroundColor: _sageGreen.withAlpha(50), 
                        child: Text(
                          userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?', 
                          style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold, fontSize: 18)
                        )
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Overview Card: Summarizing registered pets
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _sageGreen, 
                  borderRadius: BorderRadius.circular(24), 
                  boxShadow: [BoxShadow(color: _sageGreen.withAlpha(60), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PET HEALTH OVERVIEW", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    const Text("2 Pets Registered", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _statusDot(Colors.greenAccent, "1 Healthy"),
                        const SizedBox(width: 16),
                        _statusDot(Colors.orangeAccent, "1 Needs Attention"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Passports Section: Horizontal List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My Pet Passports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                  TextButton(
                    onPressed: () {}, 
                    child: Text("+ Add Pet", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _petPassportCard("Buddy", "Dog", "Golden Retriever", "3 yrs", "28.5 kg", "https://images.unsplash.com/photo-1552053831-71594a27632d?w=200", _lightBronze),
                    _petPassportCard("Luna", "Cat", "Persian", "2 yrs", "4.2 kg", "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200", _drySage),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Quick Actions Grid
              Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _actionButton(Icons.medical_services, "Meds", _lightBronze.withAlpha(60)),
                  _actionButton(Icons.calendar_today, "Book Vet", _desertSand.withAlpha(80)),
                  _actionButton(Icons.restaurant, "Nutrition", _drySage.withAlpha(60)),
                  _actionButton(Icons.assignment, "Records", _ashGrey.withAlpha(60)),
                ],
              ),
              const SizedBox(height: 32),

              // 5. Reminders List
              Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal)),
              const SizedBox(height: 12),
              _reminderTile("Bordetella Vaccine Due", "Buddy • 5 Nov 2024", _lightBronze),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      // 6. Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)]
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _dustyOlive,
          unselectedItemColor: _ashGrey,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Health"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Bookings"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _petPassportCard(String name, String species, String breed, String age, String weight, String url, Color accent) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(url, height: 100, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                Text("$species • $breed", style: TextStyle(color: _ashGrey, fontSize: 10)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(age, accent),
                    _infoChip(weight, accent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)), 
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 55, width: 55, 
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), 
          child: Icon(icon, color: _dustyOlive, size: 26)
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkCharcoal)),
      ],
    );
  }

  Widget _reminderTile(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle), 
            child: Icon(Icons.notifications_active_outlined, color: color, size: 22)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkCharcoal)), 
                Text(subtitle, style: TextStyle(color: _ashGrey, fontSize: 12))
              ]
            )
          ),
        ],
      ),
    );
  }
}
