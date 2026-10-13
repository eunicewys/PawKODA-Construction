import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutritional_provider.dart';
import '../../services/pet_service.dart';
import '../nutrition/nutrition_engine_screen.dart';
import '../widgets/fringe_header.dart';
import 'health_issues_screen.dart' show HealthIssuesScreen;
import 'vaccination_screen.dart' show VaccinationScreen;
import 'daily_activity_screen.dart' show DailyActivityScreen;

/// HealthScreen: Main Health Section hub in bottom navigation.
/// Offers 4 modules: Nutrition, Health Issues, Vaccines/Deworming, and Daily Activity Diary.
class HealthScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const HealthScreen({super.key, this.onBackPressed});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _darkCharcoal = const Color(0xFF2D3142);

  final PetService _petService = PetService();
  String? _selectedPetId;

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid ?? "";

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _drySage,
      body: StreamBuilder<List<PetProfile>>(
        stream: _petService.streamUserPets(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Column(
              children: [
                FringeHeader(
                  title: "PET HEALTH",
                  subtitle: "Loading...",
                  onBack: () {},
                ),
                const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white))),
              ],
            );
          }

          final pets = snapshot.data ?? [];
          
          if (pets.isNotEmpty && _selectedPetId != null && !pets.any((p) => p.id == _selectedPetId)) {
            // Selected pet was deleted
            _selectedPetId = null;
          }

          final selectedPet = _selectedPetId != null 
            ? pets.firstWhere((p) => p.id == _selectedPetId, orElse: () => pets.first)
            : null;

          return Column(
            children: [
              FringeHeader(
                title: "PET HEALTH",
                subtitle: selectedPet != null 
                    ? "Managing ${selectedPet.name}'s Health" 
                    : (pets.isNotEmpty ? "Please select a pet below" : "Please add a pet first"),
                onBack: widget.onBackPressed,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Selector Dropdown Header
                      if (pets.isNotEmpty) ...[
                        const Text("SELECT PET", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: selectedPet != null 
                                ? _powderPetal // Warm Morandi Powder Petal accent color when pet is selected
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selectedPet != null ? _dustyOlive : const Color(0xFFCB997E), 
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedPet != null 
                                    ? _dustyOlive.withAlpha(50) 
                                    : Colors.black.withAlpha(20), 
                                blurRadius: 10, 
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPetId ?? "",
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.pets_rounded, 
                                color: selectedPet != null ? _dustyOlive : const Color(0xFFCB997E), 
                                size: 22
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                            ),
                            dropdownColor: Colors.white,
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: _darkCharcoal, 
                              fontSize: 15
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: "",
                                child: Text(
                                  "-- Please select a pet --",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.grey.shade600, 
                                    fontStyle: FontStyle.italic
                                  ),
                                ),
                              ),
                              ...pets.map((pet) => DropdownMenuItem<String>(
                                value: pet.id,
                                child: Text(
                                  "${pet.name} (${pet.breed})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: _darkCharcoal
                                  ),
                                ),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedPetId = (val == null || val.isEmpty) ? null : val);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (selectedPet != null) ...[
                        const Text("HEALTH MODULES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                        const SizedBox(height: 12),

                      // Module 1: Nutrition Engine
                      _buildModuleCard(
                        icon: Icons.restaurant_rounded,
                        title: "Nutrition Engine",
                        subtitle: "Calculate calories and nutrients",
                        color: _desertSand,
                        onTap: () {
                          Provider.of<NutritionalProvider>(context, listen: false).setSelectedPet(selectedPet);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionEngineScreen()));
                        },
                      ),
                      const SizedBox(height: 14),

                      // Module 2: Diseases & Health Issues
                      _buildModuleCard(
                        icon: Icons.healing_rounded,
                        title: "Medical Conditions",
                        subtitle: "Log diseases or health issues",
                        color: _powderPetal,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HealthIssuesScreen(pet: selectedPet)));
                        },
                      ),
                      const SizedBox(height: 14),

                      // Module 3: Vaccines & Deworming Dosage Log
                      _buildModuleCard(
                        icon: Icons.vaccines_rounded,
                        title: "Vax & Deworm",
                        subtitle: "Log doses and set reminders",
                        color: _desertSand,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VaccinationScreen(pet: selectedPet)));
                        },
                      ),
                      const SizedBox(height: 14),

                      // Module 4: Pet Daily Activity Diary
                      _buildModuleCard(
                        icon: Icons.edit_note_rounded,
                        title: "Daily Activity",
                        subtitle: "Record pet's activity everyday",
                        color: _powderPetal,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DailyActivityScreen(pet: selectedPet)));
                        },
                      ),
                      const SizedBox(height: 80),
                    ] else if (pets.isNotEmpty) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.pets_rounded, size: 64, color: Colors.white.withAlpha(100)),
                            const SizedBox(height: 16),
                            Text(
                              "Please select a pet above\nto access health modules.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.add_circle_outline_rounded, size: 64, color: Colors.white.withAlpha(100)),
                            const SizedBox(height: 16),
                            Text(
                              "Add a pet first to start\nmanaging their health.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ], // Close Column's children
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 90, // Fixed height to make all boxes the same size
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: _dustyOlive, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkCharcoal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
