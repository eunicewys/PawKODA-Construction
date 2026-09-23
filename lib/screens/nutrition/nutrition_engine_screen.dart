import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/ingredient_model.dart';
import '../../providers/nutritional_provider.dart';
import '../widgets/fringe_header.dart';
import 'widgets/caloric_status_banner.dart';
import 'widgets/safety_alert_dialog.dart';

class NutritionEngineScreen extends StatefulWidget {
  const NutritionEngineScreen({super.key});

  @override
  State<NutritionEngineScreen> createState() => _NutritionEngineScreenState();
}

class _NutritionEngineScreenState extends State<NutritionEngineScreen> {
  // Official Morandi Colors
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _errorCoral = const Color(0xFFB56576); 
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkCharcoal = const Color(0xFF2D3142);

  List<Ingredient> _allIngredients = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final String response = await rootBundle.loadString('assets/data/ingredients.json');
    final data = await json.decode(response) as List;
    setState(() {
      _allIngredients = data.map((i) => Ingredient.fromMap(i)).toList();
    });
  }

  void _handleIngredientTap(Ingredient item) {
    final provider = Provider.of<NutritionalProvider>(context, listen: false);
    final warning = provider.checkIngredientSafety(item);

    if (warning != null) {
      showDialog(
        context: context,
        builder: (context) => SafetyAlertDialog(
          title: "Safety Alert!",
          message: warning,
          alternatives: _allIngredients
              .where((i) => provider.checkIngredientSafety(i) == null && i.category == item.category)
              .take(3)
              .map((i) => i.name)
              .toList(),
        ),
      );
    } else {
      _showPortionModal(item);
    }
  }

  void _showPortionModal(Ingredient item) {
    double selectedMass = 100.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          final scaled = item.nutrientsPer100g.scale(selectedMass);
          return AlertDialog(
            backgroundColor: const Color(0xFFFBFBFB), // Creamy white
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Add ${item.name}", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _nutrientRow("Calories", "${scaled.kcal.toInt()} kcal"),
                _nutrientRow("Protein", "${scaled.proteinGrams.toStringAsFixed(1)}g"),
                _nutrientRow("Fat", "${scaled.fatGrams.toStringAsFixed(1)}g"),
                _nutrientRow("Calcium", "${scaled.calciumMg.toInt()} mg"),
                const SizedBox(height: 20),
                Text("${selectedMass.toInt()}g", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _dustyOlive)),
                Slider(
                  value: selectedMass,
                  min: 10,
                  max: 500,
                  divisions: 49,
                  activeColor: _dustyOlive,
                  onChanged: (val) => setMState(() => selectedMass = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: _ashGrey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _dustyOlive),
                onPressed: () {
                  Provider.of<NutritionalProvider>(context, listen: false).addIngredient(item, selectedMass);
                  Navigator.pop(context);
                },
                child: const Text("Add to Bowl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _nutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _ashGrey, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionalProvider>();
    final pet = provider.selectedPet;

    if (pet == null) return const Scaffold(body: Center(child: Text("No pet selected")));

    return Scaffold(
      backgroundColor: _desertSand, 
      body: Column(
        children: [
          FringeHeader(
            title: "Nutrition Engine",
            subtitle: "${pet.name} • ${pet.breed}",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. METABOLIC PROFILE HEADER
                  _buildMetabolicHeader(pet, provider),
                  const SizedBox(height: 24),

                  // 2. INTERACTIVE BOWL WIDGET
                  _buildFeedingBowl(provider),
                  const SizedBox(height: 24),

                  // 4. NUTRIENT ANALYSIS PROGRESS BARS
                  _buildNutrientAnalysis(provider),
                  
                  // 5 & 6. STATUS BANNER
                  if (provider.bowl.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildCaloricDisplay(provider),
                  ],

                  const SizedBox(height: 24),

                  // 7. ADD INGREDIENTS SECTION
                  _buildAddIngredientsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicHeader(PetProfile pet, NutritionalProvider provider) {
    String conditionLabel = pet.condition.name.toUpperCase();
    if (pet.gender == Gender.female && pet.condition == PetCondition.intact) {
      conditionLabel = "INTACT";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _dustyOlive,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _dustyOlive.withAlpha(60), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("METABOLIC PROFILE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showMetabolicInfo(),
                child: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _profileStat("Met. Weight", "${pet.weightKg} kg"),
              _profileStat("Gender", pet.gender.name.toUpperCase()),
              _profileStat("Status", conditionLabel),
            ],
          ),
          const SizedBox(height: 24),
          // Highlighted Daily Goal
          _bigStatBox("DAILY ENERGY GOAL (DER)", "${provider.targetDER.toInt()} kcal/day", isPrimary: true),
          const SizedBox(height: 12),
          // Supporting Resting Baseline
          _bigStatBox("RESTING BASELINE (RER)", "${provider.currentRER.toInt()} kcal/day", isPrimary: false),
        ],
      ),
    );
  }

  void _showMetabolicInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Metabolic Information", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoItem("Daily Energy Goal (DER)", "The actual calories your pet needs based on its weight, age, and reproductive status."),
            const SizedBox(height: 16),
            _infoItem("Resting Baseline (RER)", "The energy needed to maintain basic life functions (heartbeat, breathing) while at rest."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Got it", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: _dustyOlive, fontSize: 16)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _profileStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _bigStatBox(String label, String value, {required bool isPrimary}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isPrimary ? 16 : 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white.withAlpha(50) : Colors.white.withAlpha(20), 
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? Border.all(color: Colors.white.withAlpha(40), width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPrimary ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildFeedingBowl(NutritionalProvider provider) {
    return Container(
      width: double.infinity,
      height: 300, // Slightly taller for the "pile up" effect
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220), 
        borderRadius: BorderRadius.circular(32), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15)]
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. BOWL BASE SHADOW (Depth)
          Positioned(
            bottom: 60,
            child: Container(
              width: 220,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: const BorderRadius.all(Radius.elliptical(110, 20)),
              ),
            ),
          ),

          // 2. MAIN BOWL BODY (3D Slanted Side View)
          Positioned(
            bottom: 70,
            child: Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_dustyOlive, _dustyOlive.withAlpha(200)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(80),
                  top: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Icon(Icons.pets, color: Colors.white.withAlpha(100), size: 40),
                ),
              ),
            ),
          ),

          // 3. THE BOWL OPENING (The Inner Circle where food sits)
          Positioned(
            bottom: 170,
            child: Container(
              width: 190,
              height: 40,
              decoration: BoxDecoration(
                color: _ashGrey.withAlpha(100),
                borderRadius: const BorderRadius.all(Radius.elliptical(95, 20)),
                border: Border.all(color: Colors.white.withAlpha(200), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)],
              ),
            ),
          ),

          // 4. FOOD PILE (Realistic High-Density Stacking)
          Positioned(
            bottom: 180,
            child: SizedBox(
              width: 180,
              height: 120,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  if (provider.bowl.isEmpty)
                    Text("Bowl is empty", style: TextStyle(color: _ashGrey.withAlpha(150), fontSize: 12, fontStyle: FontStyle.italic))
                  else
                    ..._buildPiledFood(provider.bowl),
                ],
              ),
            ),
          ),
          
          // 5. RESET BUTTON (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: InkWell(
              onTap: () => provider.clearBowl(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _dustyOlive.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: _dustyOlive),
                    const SizedBox(width: 4),
                    Text("RESET", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),

          // 6. INGREDIENT CHIPS (Horizontal list at the very bottom)
          Positioned(
            bottom: 12,
            child: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: provider.bowl.map((item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text("${item.ingredient.name} (${item.massGrams.toInt()}g)", style: TextStyle(fontSize: 10, color: _darkCharcoal)),
                      backgroundColor: _getFoodColor(item.ingredient.category).withAlpha(40),
                      onDeleted: () => provider.removeIngredient(item.ingredient.ingredientId),
                      deleteIconColor: _darkCharcoal.withAlpha(150),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPiledFood(List<BowlIngredient> bowl) {
    List<Widget> bits = [];
    int globalIdx = 0;
    const int rowSize = 5; // Slightly narrower row for tighter gathering
    const double xSpacing = 30.0;
    const double ySpacing = 20.0;
    const double startX = 25.0;

    for (var item in bowl) {
      // New Logic: 10-50g=2, 51-100g=4, 101-150g=6, 151-200g=8
      int numBits = (item.massGrams / 50).ceil() * 2;
      
      for (int i = 0; i < numBits; i++) {
        int row = globalIdx ~/ rowSize;
        int col = globalIdx % rowSize;
        
        // Offset every other row for a more natural "staggered" pile
        double xOffset = (col * xSpacing) + (row % 2 == 0 ? 0 : 15);
        double yOffset = (row * ySpacing);
        
        bits.add(
          Positioned(
            bottom: yOffset,
            left: startX + xOffset,
            child: _buildFoodBit(item.ingredient),
          ),
        );
        globalIdx++;
      }
    }
    return bits;
  }

  Widget _buildFoodBit(Ingredient ingredient) {
    Color baseColor = _getFoodColor(ingredient.category);
    IconData icon;
    String cat = ingredient.category.toLowerCase();

    if (cat.contains('meat') || cat.contains('poultry') || cat.contains('beef') || cat.contains('chicken')) {
      icon = Icons.favorite_rounded;
    } else if (cat.contains('veg') || cat.contains('green') || cat.contains('leafy')) {
      icon = Icons.eco_rounded;
    } else if (cat.contains('fruit') || cat.contains('berry')) {
      icon = Icons.circle_rounded;
    } else {
      icon = Icons.grain_rounded;
    }

    return Container(
      width: 36, // Increased from 32 for a fuller look with fewer bits
      height: 36,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 5,
            offset: const Offset(1, 2),
          )
        ],
        gradient: RadialGradient(
          colors: [baseColor, baseColor.withAlpha(200)],
          center: const Alignment(-0.3, -0.3),
        ),
      ),
      child: Center(
        child: Icon(
          icon, 
          color: Colors.white.withAlpha(180), 
          size: 18
        ),
      ),
    );
  }

  Color _getFoodColor(String category) {
    String c = category.toLowerCase();
    // High-Contrast Colors (Vibrant and distinct from Desert Sand/White)
    if (c.contains('meat') || c.contains('poultry') || c.contains('beef') || c.contains('chicken')) {
      return const Color(0xFF4E342E); // Dark Chocolate Brown
    }
    if (c.contains('veg') || c.contains('green') || c.contains('leafy')) {
      return const Color(0xFF2E7D32); // Vibrant Forest Green
    }
    if (c.contains('fruit') || c.contains('berry')) {
      return const Color(0xFFC62828); // Bright Cherry Red
    }
    if (c.contains('grain') || c.contains('carb') || c.contains('rice')) {
      return const Color(0xFFFF8F00); // Deep Golden Amber
    }
    return const Color(0xFF455A64); // Blue Grey for others
  }

  Widget _buildNutrientAnalysis(NutritionalProvider provider) {
    final n = provider.totalNutrients;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("NUTRIENT ANALYSIS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkCharcoal)),
          const SizedBox(height: 20),
          _nutrientBar("PROTEIN", n.proteinGrams, 50, Colors.teal),
          _nutrientBar("FAT", n.fatGrams, 30, Colors.orange),
          _nutrientBar("CALCIUM", n.calciumMg / 1000, 2, Colors.purple),
          _nutrientBar("VITAMINS", n.vitaminsGrams, 1, Colors.pink),
          _nutrientBar("MINERALS", n.mineralsGrams, 1, Colors.blueGrey),
          
          const Divider(height: 32, thickness: 1),
          
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOTAL CALORIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFB7B7A4), letterSpacing: 0.5)),
                  Text("${provider.totalNutrients.kcal.toInt()} kcal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: _darkCharcoal)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutrientBar(String label, double current, double max, Color color) {
    double progress = (current / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _ashGrey)),
              Text("${current.toStringAsFixed(1)}g", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress, backgroundColor: color.withAlpha(40), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  Widget _buildCaloricDisplay(NutritionalProvider provider) {
    if (provider.bowl.isEmpty) return const SizedBox.shrink();
    return CaloricStatusBanner(status: provider.adequacyStatus, petName: provider.selectedPet?.name ?? "Pet");
  }

  Widget _buildAddIngredientsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ADD INGREDIENTS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkCharcoal)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search food (try: chicken, broccoli...)",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.qr_code_scanner),
              fillColor: _powderPetal.withAlpha(100),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Suggested for your pet:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allIngredients.take(6).map((item) => ActionChip(
              label: Text(item.name, style: const TextStyle(fontSize: 11)),
              backgroundColor: _desertSand.withAlpha(50),
              onPressed: () => _handleIngredientTap(item),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
