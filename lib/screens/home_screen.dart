import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/**
 * HomeScreen: The main dashboard featuring pet passports, quick actions, and reminders.
 * Updated with official Morandi Natural Palette.
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Morandi Palette Constants
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkText = const Color(0xFF2D3142);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 18) return "Good afternoon,";
    return "Good evening,";
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final String userName = userProvider.displayName ?? 'Friend';

    return Scaffold(
      backgroundColor: _powderPetal, // Official soft background
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
                      Row(
                        children: [
                          Text(
                            "$userName 👋",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkText),
                          ),
                          if (userProvider.role != null && userProvider.role != 'owner') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: userProvider.role == 'admin' ? const Color(0xFFB56576).withAlpha(50) : _lightBronze.withAlpha(50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                userProvider.role!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: userProvider.role == 'admin' ? const Color(0xFFB56576) : _lightBronze,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24, 
                    backgroundColor: _drySage.withAlpha(80), 
                    child: Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?', 
                      style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold)
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Overview Card: Dusty Olive / Dry Sage
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _dustyOlive, 
                  borderRadius: BorderRadius.circular(24), 
                  boxShadow: [BoxShadow(color: _dustyOlive.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pet Health Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Everything looks good today!", style: TextStyle(color: _powderPetal.withAlpha(200), fontSize: 12)),
                  ],
                ),
              ),
              
              if (userProvider.role == 'admin') ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    label: const Text("Admin Management Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),

              // 3. Horizontal List: My Pet Passports
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My Pet Passports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
                  TextButton(onPressed: () {}, child: Text("+ Add Pet", style: TextStyle(color: _lightBronze))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _PetCard(name: "Buddy", species: "Dog", age: "3 yrs", weight: "28.5 kg", imageUrl: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=200", accent: _lightBronze),
                    _PetCard(name: "Luna", species: "Cat", age: "2 yrs", weight: "4.2 kg", imageUrl: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200", accent: _drySage),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Grid: Quick Actions (Blend of Palette)
              Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _ActionItem(icon: Icons.medical_services, label: "Meds", color: _lightBronze.withAlpha(50)),
                  _ActionItem(icon: Icons.calendar_today, label: "Book Vet", color: _desertSand.withAlpha(80)),
                  _ActionItem(icon: Icons.restaurant, label: "Nutrition", color: _drySage.withAlpha(50)),
                  _ActionItem(icon: Icons.assignment, label: "Records", color: _ashGrey.withAlpha(50)),
                ],
              ),
              const SizedBox(height: 32),

              // 5. List: Upcoming Reminders
              Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              _ReminderTile(title: "Bordetella Vaccine Due", subtitle: "Buddy • 5 Nov 2024", iconColor: _lightBronze),
              const SizedBox(height: 80), // Padding for Bottom Nav
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
}

class _PetCard extends StatelessWidget {
  final String name, species, age, weight, imageUrl;
  final Color accent;
  const _PetCard({required this.name, required this.species, required this.age, required this.weight, required this.imageUrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                Text(species, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_InfoChip(age, accent), _InfoChip(weight, accent)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)), 
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionItem({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 55, 
        width: 55, 
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), 
        child: Icon(icon, color: const Color(0xFF6B705C), size: 26)
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
    ]);
  }
}

class _ReminderTile extends StatelessWidget {
  final String title, subtitle;
  final Color iconColor;
  const _ReminderTile({required this.title, required this.subtitle, required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: iconColor.withAlpha(30), shape: BoxShape.circle), 
            child: Icon(Icons.vaccines, color: iconColor, size: 20)
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        ],
      ),
    );
  }
}
