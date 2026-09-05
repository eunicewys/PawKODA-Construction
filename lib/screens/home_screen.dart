import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/**
 * HomeScreen: The main dashboard featuring pet passports, quick actions, and reminders.
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Dynamic greeting based on current hour
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 18) return "Good afternoon,";
    return "Good evening,";
  }

  @override
  Widget build(BuildContext context) {
    // Watch UserProvider for real-time updates
    final userProvider = context.watch<UserProvider>();
    final String userName = userProvider.displayName ?? 'Friend';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
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
                      Text(_getGreeting(), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      Text("$userName 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    ],
                  ),
                  CircleAvatar(radius: 24, backgroundColor: const Color(0xFF759C86).withAlpha(51), child: Text(userName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFF759C86), fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Overview Card: Solid Green Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF759C86), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF759C86).withAlpha(76), blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pet Health Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Everything looks good today!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Horizontal List: My Pet Passports
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("My Pet Passports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  TextButton(onPressed: () {}, child: const Text("+ Add Pet", style: TextStyle(color: Color(0xFF759C86)))),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _PetCard(name: "Buddy", species: "Dog", age: "3 yrs", weight: "28.5 kg", imageUrl: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=200"),
                    _PetCard(name: "Luna", species: "Cat", age: "2 yrs", weight: "4.2 kg", imageUrl: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200"),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Grid: Quick Actions
              const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                children: const [
                  _ActionItem(icon: Icons.medical_services, label: "Meds", color: Color(0xFFF9E3E3)),
                  _ActionItem(icon: Icons.calendar_today, label: "Book Vet", color: Color(0xFFE3F2FD)),
                  _ActionItem(icon: Icons.restaurant, label: "Nutrition", color: Color(0xFFFFF9C4)),
                  _ActionItem(icon: Icons.assignment, label: "Records", color: Color(0xFFF3E5F5)),
                ],
              ),
              const SizedBox(height: 32),

              // 5. List: Upcoming Reminders
              const Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 12),
              const _ReminderTile(title: "Bordetella Vaccine Due", subtitle: "Buddy • 5 Nov 2024"),
              const SizedBox(height: 80), // Padding for Bottom Nav
            ],
          ),
        ),
      ),
      // 6. Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF759C86),
          unselectedItemColor: Colors.grey,
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

// Reusable Pet Card
class _PetCard extends StatelessWidget {
  final String name, species, age, weight, imageUrl;
  const _PetCard({required this.name, required this.species, required this.age, required this.weight, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(species, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_InfoChip(age), _InfoChip(weight)]),
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
  const _InfoChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF0F4F2), borderRadius: BorderRadius.circular(8)), child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF759C86))));
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
      Container(height: 50, width: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFF2D3142).withAlpha(153))),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _ReminderTile extends StatelessWidget {
  final String title, subtitle;
  const _ReminderTile({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF0F4F2), shape: BoxShape.circle), child: const Icon(Icons.vaccines, color: Color(0xFF759C86), size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        ],
      ),
    );
  }
}
