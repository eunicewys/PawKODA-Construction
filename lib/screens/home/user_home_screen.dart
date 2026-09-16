import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

/// UserHomeScreen: Redesigned dashboard for Pet Owners.
/// Features a "Modern Layered" pet passport experience and prioritized actions.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Official Morandi Natural Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkCharcoal = const Color(0xFF2D3142);

  // Controller for the layered pet cards
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page!;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 18) return "Good afternoon,";
    return "Good evening,";
  }

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
      backgroundColor: _drySage, // New natural background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                        Text("$userName 👋", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _powderPetal.withAlpha(100), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withAlpha(50),
                            child: Text(
                              userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. MINI OVERVIEW CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _powderPetal.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "2 Pets Registered: ",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const Text(
                        "1 Healthy, 1 Needs Attention",
                        style: TextStyle(color: Colors.white, fontSize: 12), // Changed to white
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 3. LAYERED PET PASSPORTS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("My Pet Passports", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _darkCharcoal.withAlpha(180), // Dark box column
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text("+ Add Pet", style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 2, // Mock for 2 pets
                  itemBuilder: (context, index) {
                    // Animation logic for layered scaling
                    double scale = (1 - ((_currentPage - index).abs() * 0.1)).clamp(0.8, 1.0);
                    
                    if (index == 0) {
                      return _buildPetCard(
                        scale: scale,
                        name: "Buddy",
                        species: "Dog",
                        breed: "Golden Retriever",
                        age: "3 yrs",
                        weight: "28.5 kg",
                        isHealthy: true,
                        imageUrl: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=400",
                      );
                    } else {
                      return _buildPetCard(
                        scale: scale,
                        name: "Luna",
                        species: "Cat",
                        breed: "Persian",
                        age: "2 yrs",
                        weight: "4.2 kg",
                        isHealthy: false,
                        imageUrl: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400",
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 40),

              // 4. QUICK ACTIONS GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionItem(Icons.restaurant, "Nutrition", _desertSand),
                    _buildActionItem(Icons.medical_services, "Meds", _powderPetal),
                    _buildActionItem(Icons.calendar_today, "Book Vet", _desertSand),
                    _buildActionItem(Icons.assignment, "Records", _powderPetal),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 5. REMINDERS SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _lightBronze.withAlpha(30), shape: BoxShape.circle),
                        child: Icon(Icons.vaccines, color: _lightBronze, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bordetella Vaccine Due", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal)),
                            Text("Buddy • 5 Nov 2024", style: TextStyle(color: _ashGrey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _ashGrey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPetCard({
    required double scale,
    required String name,
    required String species,
    required String breed,
    required String age,
    required String weight,
    required bool isHealthy,
    required String imageUrl,
  }) {
    return Transform.scale(
      scale: scale,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            // Image with rounded corners and health badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                  // Health Badge (Lecturer Request)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: isHealthy ? Colors.green : Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            isHealthy ? "Healthy" : "Needs Attention",
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: isHealthy ? Colors.green : Colors.red
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pet Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                        Text(species, style: TextStyle(color: _ashGrey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(breed, style: TextStyle(color: _ashGrey, fontSize: 14)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip("Age", age, _lightBronze),
                        _buildInfoChip("Weight", weight, _drySage),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 14, color: _darkCharcoal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            color: color, // Using Powder Petal or Desert Sand directly
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: _dustyOlive, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.home_filled, "Home", true),
          _navIcon(Icons.favorite_border, "Health", false),
          _navIcon(Icons.calendar_month_outlined, "Bookings", false),
          _navIcon(Icons.person_outline, "Profile", false),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? _dustyOlive : _ashGrey, size: 26),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? _dustyOlive : _ashGrey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
