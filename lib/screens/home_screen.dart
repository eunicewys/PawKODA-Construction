import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/**
 * HomeScreen: The main dashboard of the app.
 * It shows the greeting, pet overview, pet passports, and quick actions.
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Simple function to determine the greeting message based on the current time
  String _getGreeting() {
    final hour = DateTime.now().hour; // Get current hour (0-23)
    if (hour < 12) {
      return "Good morning,";
    } else if (hour < 18) {
      return "Good afternoon,";
    } else {
      return "Good evening,";
    }
  }

  @override
  Widget build(BuildContext context) {
    // We "watch" the UserProvider to automatically refresh if user data changes
    final userProvider = context.watch<UserProvider>();
    final String userName = userProvider.displayName ?? 'Friend';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8), // Soft white background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Row(
                        children: [
                          Text(
                            "$userName 👋",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                          ),
                          if (userProvider.role != null && userProvider.role != 'owner') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: userProvider.role == 'admin' ? Colors.redAccent.withAlpha(50) : Colors.blueAccent.withAlpha(50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                userProvider.role!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: userProvider.role == 'admin' ? Colors.redAccent : Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // Simple circle with the user's first initial
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF759C86).withAlpha(51),
                    child: Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF759C86), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- OVERVIEW CARD SECTION ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF759C86), // Primary Green
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF759C86).withAlpha(76), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PET HEALTH OVERVIEW", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    SizedBox(height: 8),
                    Text("2 Pets Registered", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _StatusIndicator(color: Colors.greenAccent, label: "1 Healthy"),
                        SizedBox(width: 16),
                        _StatusIndicator(color: Colors.orangeAccent, label: "1 Needs Attention"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- ADMIN PANEL (ONLY FOR ADMINS) ---
              if (userProvider.role == 'admin') ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Admin Panel access requested")),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    label: const Text("Admin Management Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3142),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],

              // --- PET PASSPORTS SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("My Pet Passports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  TextButton(onPressed: () {}, child: const Text("+ Add Pet", style: TextStyle(color: Color(0xFF759C86)))),
                ],
              ),
              const SizedBox(height: 12),
              // Horizontal scrollable list for pet cards
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _PetCard(
                      name: "Buddy",
                      breed: "Golden Retriever",
                      age: "3 yrs",
                      weight: "28.5 kg",
                      imageUrl: "https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=200&q=80",
                    ),
                    _PetCard(
                      name: "Luna",
                      breed: "Persian",
                      age: "2 yrs",
                      weight: "4.2 kg",
                      imageUrl: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=200&q=80",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- QUICK ACTIONS SECTION ---
              const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              // Grid of 4 simple action buttons
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: const [
                  _ActionItem(icon: Icons.medical_services, label: "Meds", color: Color(0xFFF9E3E3)),
                  _ActionItem(icon: Icons.calendar_today, label: "Book Vet", color: Color(0xFFE3F2FD)),
                  _ActionItem(icon: Icons.restaurant, label: "Nutrition", color: Color(0xFFFFF9C4)),
                  _ActionItem(icon: Icons.assignment, label: "Records", color: Color(0xFFF3E5F5)),
                ],
              ),
              const SizedBox(height: 32),

              // --- REMINDERS SECTION ---
              const Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 12),
              const _ReminderTile(title: "Bordetella Vaccine Due", subtitle: "Buddy • 5 Nov 2024", isDue: true),
              const SizedBox(height: 80), // Space for bottom navigation bar
            ],
          ),
        ),
      ),
      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, spreadRadius: 0)],
        ),
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

// Small helper widget for the status dots (Healthy / Attention)
class _StatusIndicator extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusIndicator({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [CircleAvatar(radius: 4, backgroundColor: color), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]);
  }
}

// Reusable widget for Pet Cards
class _PetCard extends StatelessWidget {
  final String name, breed, age, weight, imageUrl;
  const _PetCard({required this.name, required this.breed, required this.age, required this.weight, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))],
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(breed, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_PetInfoChip(label: age), _PetInfoChip(label: weight)]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Small chip for pet details like age and weight
class _PetInfoChip extends StatelessWidget {
  final String label;
  const _PetInfoChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF0F4F2), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF759C86))),
    );
  }
}

// Reusable widget for Quick Action buttons
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionItem({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(height: 50, width: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFF2D3142).withAlpha(153), size: 24)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
    ]);
  }
}

// Reusable widget for Reminder tiles
class _ReminderTile extends StatelessWidget {
  final String title, subtitle;
  final bool isDue;
  const _ReminderTile({required this.title, required this.subtitle, required this.isDue});
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
          if (isDue) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)), child: const Text("Due", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
