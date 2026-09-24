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
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _profileStat("Met. Weight", "${pet.weightKg} kg"),
                const SizedBox(width: 16),
                _profileStat("Gender", pet.gender.name.toUpperCase()),
                const SizedBox(width: 16),
                _profileStat("Status", conditionLabel),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Highlighted Daily Goal (DER)
          _bigStatBox("DAILY ENERGY GOAL (DER)", "${provider.targetDER.toInt()} kcal/day", isPrimary: true),
          const SizedBox(height: 10),
          // Supporting Resting Baseline (RER)
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
      padding: EdgeInsets.symmetric(vertical: isPrimary ? 12 : 10, horizontal: 14),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white.withAlpha(50) : Colors.white.withAlpha(20), 
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? Border.all(color: Colors.white.withAlpha(40), width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label, 
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.white70, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 0.5
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value, 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: isPrimary ? 16 : 13
              ),
            ),
          ),
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

    // Tight squeeze offsets for bits belonging to a single ingredient pile
    // Small step increments ensure bits overlap closely into one unified mound
    const List<Offset> squeezeOffsets = [
      Offset(0, 0),        // Bit 0: Base center
      Offset(-7, 4),       // Bit 1: Slightly left & up
      Offset(7, 4),        // Bit 2: Slightly right & up
      Offset(-1, 10),      // Bit 3: Stacked center
      Offset(-9, 15),      // Bit 4: Upper left
      Offset(9, 15),       // Bit 5: Upper right
      Offset(0, 20),       // Bit 6: Peak center
      Offset(-6, 25),      // Bit 7: Peak left
      Offset(6, 25),       // Bit 8: Peak right
      Offset(0, 29),       // Bit 9: Topmost
    ];

    int totalItems = bowl.length;

    for (int itemIdx = 0; itemIdx < totalItems; itemIdx++) {
      var item = bowl[itemIdx];

      // Determine cluster center X and Y for this ingredient group
      double clusterCenterX;
      double clusterCenterY;

      if (totalItems == 1) {
        clusterCenterX = 90;
        clusterCenterY = 10;
      } else if (totalItems == 2) {
        clusterCenterX = itemIdx == 0 ? 55 : 125;
        clusterCenterY = 10;
      } else if (totalItems == 3) {
        clusterCenterX = itemIdx == 0 ? 40 : (itemIdx == 1 ? 90 : 140);
        clusterCenterY = itemIdx == 1 ? 16 : 10; // Middle group slightly behind
      } else if (totalItems == 4) {
        clusterCenterX = 32 + (itemIdx * 38);
        clusterCenterY = itemIdx % 2 == 1 ? 16 : 10;
      } else {
        // 5+ items arranged in wrap slots
        int row = itemIdx ~/ 3;
        int col = itemIdx % 3;
        clusterCenterX = 40 + (col * 50);
        clusterCenterY = 8 + (row * 22);
      }

      // Calculate number of bits based on weight: 10-50g=2, 51-100g=4, 101-150g=6
      int numBits = (item.massGrams / 50).ceil() * 2;

      for (int i = 0; i < numBits; i++) {
        Offset offset = squeezeOffsets[i % squeezeOffsets.length];

        double bitX = clusterCenterX + offset.dx - 15; // 15 is half bit width (30)
        double bitY = clusterCenterY + offset.dy;

        bits.add(
          Positioned(
            bottom: bitY,
            left: bitX,
            child: _buildFoodBit(item.ingredient),
          ),
        );
      }
    }

    return bits;
  }

  Widget _buildFoodBit(Ingredient ingredient) {
    final style = _getFoodBitStyle(ingredient.category);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: style.borderRadius,
        border: Border.all(
          color: Colors.white.withAlpha(150), // Soft glass-like translucent rim
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: style.mainColor.withAlpha(80),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
        gradient: LinearGradient(
          colors: style.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          style.icon, 
          color: Colors.white.withAlpha(220), 
          size: 15,
        ),
      ),
    );
  }

  _FoodBitStyle _getFoodBitStyle(String category) {
    String c = category.toLowerCase();

    // 1. VEGETABLES / LEAFY (e.g. Broccoli, Carrots, Pumpkin, Sweet Potato)
    if (c.contains('veg') || c.contains('green') || c.contains('leafy') || c.contains('broccoli')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFF2E7D32),
        gradientColors: [
          const Color(0xFF81C784).withAlpha(220), // Translucent light green
          const Color(0xFF2E7D32).withAlpha(190), // Translucent deep foliage green
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        icon: Icons.eco_rounded,
      );
    }

    // 2. POULTRY / CHICKEN / TURKEY
    if (c.contains('poultry') || c.contains('chicken') || c.contains('turkey')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFFD97724),
        gradientColors: [
          const Color(0xFFFCD3A1).withAlpha(220), // Soft warm golden highlight
          const Color(0xFFD97724).withAlpha(190), // Translucent roasted honey chicken
        ],
        borderRadius: BorderRadius.circular(12),
        icon: Icons.restaurant_rounded,
      );
    }

    // 3. MEAT / BEEF / ORGAN MEAT
    if (c.contains('meat') || c.contains('beef') || c.contains('organ')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFF6D4C41),
        gradientColors: [
          const Color(0xFFA1887F).withAlpha(220),
          const Color(0xFF5D4037).withAlpha(190),
        ],
        borderRadius: BorderRadius.circular(10),
        icon: Icons.pets,
      );
    }

    // 4. FISH / SALMON
    if (c.contains('fish') || c.contains('salmon') || c.contains('seafood')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFFE64A19),
        gradientColors: [
          const Color(0xFFFFAB91).withAlpha(220),
          const Color(0xFFE64A19).withAlpha(190),
        ],
        borderRadius: BorderRadius.circular(10),
        icon: Icons.set_meal_rounded,
      );
    }

    // 5. PROTEIN / EGG
    if (c.contains('egg') || c.contains('protein')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFFFFB300),
        gradientColors: [
          const Color(0xFFFFE082).withAlpha(220),
          const Color(0xFFFFB300).withAlpha(190),
        ],
        borderRadius: BorderRadius.circular(15),
        icon: Icons.egg_rounded,
      );
    }

    // 6. FRUIT / BERRY
    if (c.contains('fruit') || c.contains('berry')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFFC62828),
        gradientColors: [
          const Color(0xFFEF9A9A).withAlpha(220),
          const Color(0xFFC62828).withAlpha(190),
        ],
        borderRadius: BorderRadius.circular(15),
        icon: Icons.circle_rounded,
      );
    }

    // 7. GRAIN / CARB / RICE
    if (c.contains('grain') || c.contains('carb') || c.contains('rice')) {
      return _FoodBitStyle(
        mainColor: const Color(0xFFF57C00),
        gradientColors: [
          const Color(0xFFFFE0B2).withAlpha(220),
          const Color(0xFFF57C00).withAlpha(190),
        ],
        borderRadius: BorderRadius.circular(12),
        icon: Icons.grain_rounded,
      );
    }

    // DEFAULT
    return _FoodBitStyle(
      mainColor: const Color(0xFF455A64),
      gradientColors: [
        const Color(0xFF90A4AE).withAlpha(220),
        const Color(0xFF455A64).withAlpha(190),
      ],
      borderRadius: BorderRadius.circular(12),
      icon: Icons.grain_rounded,
    );
  }

  Color _getFoodColor(String category) {
    return _getFoodBitStyle(category).mainColor;
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

  List<Ingredient> get _filteredIngredients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allIngredients.take(6).toList(); // Top 6 suggested ingredients
    }
    return _allIngredients
        .where((i) => i.name.toLowerCase().contains(query) || i.category.toLowerCase().contains(query))
        .take(9)
        .toList();
  }

  Widget _buildCaloricDisplay(NutritionalProvider provider) {
    if (provider.bowl.isEmpty) return const SizedBox.shrink();
    return CaloricStatusBanner(status: provider.adequacyStatus, petName: provider.selectedPet?.name ?? "Pet");
  }

  Widget _buildAddIngredientsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ADD INGREDIENTS", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkCharcoal)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search food (try: chicken, broccoli...)",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : const Icon(Icons.qr_code_scanner, size: 20),
              fillColor: _powderPetal.withAlpha(80),
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _searchController.text.isEmpty ? "Suggested for your pet:" : "Search Results:", 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;
              // 3 per row on standard phone screens (> 300px), else 2
              final int numColumns = availableWidth > 300 ? 3 : 2;
              const double spacing = 6.0;
              final double itemWidth = (availableWidth - (spacing * (numColumns - 1))) / numColumns;

              final displayedList = _filteredIngredients;

              if (displayedList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("No matching ingredients found.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                );
              }

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: displayedList.map((item) {
                  final style = _getFoodBitStyle(item.category);
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () => _handleIngredientTap(item),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: style.mainColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: style.mainColor.withAlpha(50), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: style.mainColor.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(style.icon, size: 10, color: style.mainColor),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _darkCharcoal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FoodBitStyle {
  final Color mainColor;
  final List<Color> gradientColors;
  final BorderRadius borderRadius;
  final IconData icon;

  const _FoodBitStyle({
    required this.mainColor,
    required this.gradientColors,
    required this.borderRadius,
    required this.icon,
  });
}
