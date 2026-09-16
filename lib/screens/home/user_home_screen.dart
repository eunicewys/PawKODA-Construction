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
    _pageController = PageController(viewportFraction: 0.8) // Reduced from 0.85 to make cards narrower
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
      backgroundColor: _drySage, // Nature background
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
                        Text(_getGreeting(), style: const TextStyle(color: Colors.white, fontSize: 17)),
                        Text(userName, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, 
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: _powderPetal, 
                            child: Text(
                              userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
                              style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold),
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
                    color: Colors.white.withAlpha(204), // Increased to 80% opacity
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.health_and_safety, color: _dustyOlive, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "2 registered:",
                              style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "1 healthy; 1 needs attention",
                              style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
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
                    const Text("My Pet Passports", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: _darkCharcoal,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)],
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, 
                          minimumSize: Size.zero, 
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap
                        ),
                        child: Text("+ Add Pet", style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              SizedBox(
                height: 350, // Reduced from 370 to 350 to fit on smaller screens
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 2, 
                  itemBuilder: (context, index) {
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
                child: const Text("Quick Actions", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
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
                child: const Text("Upcoming Reminders", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        child: Icon(Icons.vaccines, color: _lightBronze, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bordetella Vaccine Due", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _darkCharcoal)),
                            Text("Buddy • 5 Nov 2024", style: TextStyle(color: _ashGrey, fontSize: 16)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _ashGrey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 100), 
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
          border: Border.all(color: _ashGrey.withAlpha(50), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), // Further reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkCharcoal)), // Reduced from 27 to 24
                        Text(species, style: TextStyle(color: _ashGrey, fontWeight: FontWeight.w600, fontSize: 14)), // Reduced from 16 to 14
                      ],
                    ),
                    Text(breed, style: TextStyle(color: _ashGrey, fontSize: 15)), // Reduced from 17 to 15
                    const SizedBox(height: 4), // Reduced from 12 to 4 to cut space
                    Row(
                      children: [
                        Expanded(child: _buildInfoChip("Age", age)),
                        const SizedBox(width: 12), // Balanced gap
                        Expanded(child: _buildInfoChip("Weight", weight)),
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

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced height from 10 to 6
      decoration: BoxDecoration(
        color: _ashGrey.withAlpha(140), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(fontSize: 12, color: _dustyOlive, fontWeight: FontWeight.bold) // Reduced from 13 to 12
          ),
          Text(value, style: TextStyle(fontSize: 15, color: _darkCharcoal, fontWeight: FontWeight.bold)), // Reduced from 17 to 15
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: _dustyOlive, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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
