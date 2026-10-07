import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/ingredient_model.dart';
import '../../models/disease_model.dart';
import '../../providers/nutritional_provider.dart';
import '../widgets/fringe_header.dart';
import 'widgets/caloric_adequacy_banner.dart';
import 'widgets/clinical_warning_box.dart';
import 'widgets/safety_alert_dialog.dart';

class NutritionEngineScreen extends StatefulWidget {
  const NutritionEngineScreen({super.key});

  @override
  State<NutritionEngineScreen> createState() => _NutritionEngineScreenState();
}

class _NutritionEngineScreenState extends State<NutritionEngineScreen> {
  // Official Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
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
          title: "Safety Interceptor Alert!",
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
            backgroundColor: const Color(0xFFFBFBFB),
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
                  // 1. TOP METABOLIC CARD & CLINICAL STATUS BADGE
                  _buildMetabolicHeader(pet, provider),
                  const SizedBox(height: 20),

                  // 2. INTERACTIVE BOWL WIDGET
                  _buildFeedingBowl(provider),
                  const SizedBox(height: 24),

                  // 3. ADD INGREDIENTS SEARCH & SELECTION
                  _buildAddIngredientsSection(),
                  const SizedBox(height: 24),

                  // 4. NUTRIENT ANALYSIS & CUMULATIVE CALORIES
                  _buildNutrientAnalysis(provider),
                  
                  // 5. CALORIC ADEQUACY BANNER, CLINICAL WARNING BOX & ACTION BUTTONS
                  if (provider.bowl.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    CaloricAdequacyBanner(
                      adequacyRatio: provider.adequacyRatio,
                      petName: pet.name,
                      isSickPet: provider.isSickPet,
                    ),
                    ClinicalWarningBox(warnings: provider.clinicalWarnings),
                    _buildBottomActionButtons(provider),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // 1. TOP METABOLIC CARD WITH DYNAMIC STATUS BADGE
  // -----------------------------------------------------------------
  Widget _buildMetabolicHeader(PetProfile pet, NutritionalProvider provider) {
    String conditionLabel = pet.condition.name.toUpperCase();
    if (pet.gender == Gender.female && pet.condition == PetCondition.intact) {
      conditionLabel = "INTACT";
    }

    final diseaseProfile = DiseaseProfile.getProfile(pet.activeDisease);

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
          const SizedBox(height: 14),

          // DYNAMIC STATUS BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: provider.isSickPet 
                  ? const Color(0xFFCB997E) // Coral / Light Bronze
                  : const Color(0xFF759C86), // Sage Green
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isSickPet ? Icons.healing_rounded : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        provider.isSickPet
                            ? "Clinical Mode: ${diseaseProfile.displayName} • Therapeutic Constraints Active"
                            : "Status: Healthy • Standard Life-Stage Engine",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (provider.isSickPet && diseaseProfile.requiresIdealWeight) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Target Weight: ${provider.idealWeight.toStringAsFixed(1)} kg (BCS ${pet.bodyConditionScore}/9)",
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _profileStat("Weight", "${pet.weightKg} kg"),
                const SizedBox(width: 16),
                _profileStat("Gender", pet.gender.name.toUpperCase()),
                const SizedBox(width: 16),
                _profileStat("Status", conditionLabel),
              ],
            ),
          ),
          const SizedBox(height: 18),
          
          _bigStatBox("DAILY ENERGY GOAL (DER)", "${provider.targetDER.toInt()} kcal/day", isPrimary: true),
          const SizedBox(height: 10),
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
            _infoItem("Daily Energy Goal (DER)", "The actual calories your pet needs based on its weight, age, condition, and clinical status."),
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
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _bigStatBox(String label, String value, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white.withAlpha(40) : Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
          const SizedBox(width: 8),
          Text(
            value, 
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: isPrimary ? 16 : 13
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // 2. INTERACTIVE BOWL WIDGET (RESTORED ORIGINAL VECTOR BOWL & STYLING)
  // -----------------------------------------------------------------
  Widget _buildFeedingBowl(NutritionalProvider provider) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230), 
        borderRadius: BorderRadius.circular(28), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4))]
      ),
      child: Stack(
        children: [
          // 1. VECTOR BOWL & ORGANIC FOOD MOUND PAINTER
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            height: 180,
            child: CustomPaint(
              painter: PetFoodBowlPainter(
                bowl: provider.bowl,
                bowlColor: _dustyOlive,
              ),
            ),
          ),
          
          // 2. RESET BUTTON (Top Right)
          Positioned(
            top: 12,
            right: 12,
            child: InkWell(
              onTap: () => provider.clearBowl(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _dustyOlive.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: _dustyOlive),
                    const SizedBox(width: 4),
                    Text("RESET", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),

          // 3. SELECTED INGREDIENTS VERTICAL LIST WITH PORTION SLIDERS
          Positioned(
            bottom: 10,
            left: 12,
            right: 12,
            child: Container(
              height: 170,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(40), width: 1),
              ),
              child: provider.bowl.isEmpty
                ? Center(
                    child: Text(
                      "Selected ingredients & portion sliders will appear here",
                      style: TextStyle(color: _ashGrey, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: provider.bowl.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = provider.bowl[index];
                      final style = _getFoodBitStyle(item.ingredient.category);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: style.mainColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: style.mainColor.withAlpha(60), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: style.mainColor.withAlpha(50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(style.icon, size: 10, color: style.mainColor),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.ingredient.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _darkCharcoal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${item.massGrams.toInt()}g",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: style.mainColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => provider.removeIngredient(index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: _darkCharcoal.withAlpha(160),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Portion Slider (Pull Lever) to dynamically adjust mass in real-time
                            SizedBox(
                              height: 22,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  trackHeight: 3,
                                  activeTrackColor: style.mainColor,
                                  inactiveTrackColor: style.mainColor.withAlpha(40),
                                  thumbColor: style.mainColor,
                                ),
                                child: Slider(
                                  value: item.massGrams.clamp(10.0, 500.0),
                                  min: 10,
                                  max: 500,
                                  divisions: 49,
                                  onChanged: (newGrams) {
                                    provider.updateIngredientGrams(index, newGrams);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // 3. ADD INGREDIENTS SECTION (RESTORED ORIGINAL CATEGORY CARDS)
  // -----------------------------------------------------------------
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
          Container(
            height: 150,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withAlpha(30), width: 1),
            ),
            child: _filteredIngredients.isEmpty
              ? const Center(
                  child: Text(
                    "No matching ingredients found.", 
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  itemCount: _filteredIngredients.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _filteredIngredients[index];
                    final style = _getFoodBitStyle(item.category);
                    return InkWell(
                      onTap: () => _handleIngredientTap(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: style.mainColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: style.mainColor.withAlpha(50), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: style.mainColor.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(style.icon, size: 12, color: style.mainColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _darkCharcoal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: style.mainColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  _FoodBitStyle _getFoodBitStyle(String category) {
    String c = category.toLowerCase();

    // 1. VEGETABLES / LEAFY (Broccoli, Carrots, Sweet Potato)
    if (c.contains('veg') || c.contains('green') || c.contains('leafy') || c.contains('broccoli')) {
      return const _FoodBitStyle(
        mainColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF81C784), Color(0xFF2E7D32)],
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        icon: Icons.eco_rounded,
      );
    }

    // 2. POULTRY / CHICKEN / TURKEY
    if (c.contains('poultry') || c.contains('chicken') || c.contains('turkey')) {
      return const _FoodBitStyle(
        mainColor: Color(0xFFD97724),
        gradientColors: [Color(0xFFFCD3A1), Color(0xFFD97724)],
        borderRadius: BorderRadius.all(Radius.circular(12)),
        icon: Icons.restaurant_rounded,
      );
    }

    // 3. MEAT / BEEF / ORGAN MEAT
    if (c.contains('meat') || c.contains('beef') || c.contains('organ')) {
      return const _FoodBitStyle(
        mainColor: Color(0xFF6D4C41),
        gradientColors: [Color(0xFFA1887F), Color(0xFF5D4037)],
        borderRadius: BorderRadius.all(Radius.circular(10)),
        icon: Icons.pets,
      );
    }

    // 4. FISH / SALMON
    if (c.contains('fish') || c.contains('salmon') || c.contains('seafood')) {
      return const _FoodBitStyle(
        mainColor: Color(0xFFE64A19),
        gradientColors: [Color(0xFFFFAB91), Color(0xFFE64A19)],
        borderRadius: BorderRadius.all(Radius.circular(10)),
        icon: Icons.set_meal_rounded,
      );
    }

    // 5. PROTEIN / EGG
    if (c.contains('egg') || c.contains('protein')) {
      return const _FoodBitStyle(
        mainColor: Color(0xFFFFB300),
        gradientColors: [Color(0xFFFFE082), Color(0xFFFFB300)],
        borderRadius: BorderRadius.all(Radius.circular(15)),
        icon: Icons.egg_rounded,
      );
    }

    // 6. FRUIT / BERRY
    if (c.contains('fruit') || c.contains('berry')) {
      return const _FoodBitStyle(
        mainColor: Color(0xFFC62828),
        gradientColors: [Color(0xFFEF9A9A), Color(0xFFC62828)],
        borderRadius: BorderRadius.all(Radius.circular(15)),
        icon: Icons.circle_rounded,
      );
    }

    // DEFAULT / GRAIN
    return const _FoodBitStyle(
      mainColor: Color(0xFF455A64),
      gradientColors: [Color(0xFF90A4AE), Color(0xFF455A64)],
      borderRadius: BorderRadius.all(Radius.circular(12)),
      icon: Icons.grain_rounded,
    );
  }

  // -----------------------------------------------------------------
  // 4. NUTRIENT ANALYSIS & CUMULATIVE CALORIES
  // -----------------------------------------------------------------
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
                  const Text("CUMULATIVE CALORIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFB7B7A4), letterSpacing: 0.5)),
                  Text(
                    "${provider.totalKcal.toInt()} kcal",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: _darkCharcoal),
                  ),
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
          LinearProgressIndicator(
            value: progress, 
            backgroundColor: color.withAlpha(40), 
            valueColor: AlwaysStoppedAnimation<Color>(color), 
            minHeight: 8, 
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // 5. BOTTOM ACTION BUTTONS WITH DISABLING REASON EXPLANATIONS
  // -----------------------------------------------------------------
  Widget _buildBottomActionButtons(NutritionalProvider provider) {
    if (provider.bowl.isEmpty) return const SizedBox.shrink();

    bool canAct = provider.canSaveOrFeed;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canAct
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: _dustyOlive,
                                content: Text("Recipe saved for ${provider.selectedPet?.name ?? 'pet'}!"),
                              ),
                            );
                          }
                        : () => _explainDisabledReason(provider),
                    icon: Icon(
                      canAct ? Icons.bookmark_added_rounded : Icons.lock_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Save Recipe",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAct ? _dustyOlive : _ashGrey,
                      disabledBackgroundColor: _ashGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: canAct
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: _dustyOlive,
                                content: Text("Feeding meal to ${provider.selectedPet?.name ?? 'pet'}! Bon appétit!"),
                              ),
                            );
                          }
                        : () => _explainDisabledReason(provider),
                    icon: Icon(
                      canAct ? Icons.restaurant_rounded : Icons.lock_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Feed Meal",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAct ? const Color(0xFF759C86) : _ashGrey,
                      disabledBackgroundColor: _ashGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!canAct) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _explainDisabledReason(provider),
              child: Text(
                provider.hasClinicalViolation
                    ? "⚠️ Action blocked by clinical safety hazard"
                    : "⚠️ Caloric target match (${provider.adequacyRatio.toStringAsFixed(1)}%) must be between 90% - 110%",
                style: TextStyle(
                  color: provider.hasClinicalViolation ? const Color(0xFFD32F2F) : _darkCharcoal,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _explainDisabledReason(NutritionalProvider provider) {
    String reason = "";
    if (provider.hasClinicalViolation) {
      reason = "Action Blocked: Active clinical safety hazard detected in recipe. Please resolve all warnings in red box.";
    } else if (provider.adequacyRatio < 90.0) {
      reason = "Action Blocked: Recipe is under-caloric (${provider.adequacyRatio.toStringAsFixed(1)}%). Target is 90% - 110%.";
    } else if (provider.adequacyRatio > 110.0) {
      reason = "Action Blocked: Recipe is over-caloric (${provider.adequacyRatio.toStringAsFixed(1)}%). Target is 90% - 110%.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD32F2F),
        duration: const Duration(seconds: 3),
        content: Text(reason),
      ),
    );
  }

  List<Ingredient> get _filteredIngredients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allIngredients;
    }
    return _allIngredients
        .where((i) => i.name.toLowerCase().contains(query) || i.category.toLowerCase().contains(query))
        .toList();
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

enum _KibbleShape { oval, sphere, leaf }

class _KibblePiece {
  final double x;
  final double y;
  final double angle;
  final double width;
  final double height;
  final Color lightColor;
  final Color darkColor;
  final Color outlineColor;
  final _KibbleShape shape;

  _KibblePiece({
    required this.x,
    required this.y,
    required this.angle,
    required this.width,
    required this.height,
    required this.lightColor,
    required this.darkColor,
    required this.outlineColor,
    required this.shape,
  });
}

class _KibbleStyle {
  final Color lightColor;
  final Color darkColor;
  final Color outlineColor;
  final _KibbleShape shape;
  final double width;
  final double height;

  const _KibbleStyle({
    required this.lightColor,
    required this.darkColor,
    required this.outlineColor,
    required this.shape,
    required this.width,
    required this.height,
  });
}

class PetFoodBowlPainter extends CustomPainter {
  final List<BowlIngredient> bowl;
  final Color bowlColor;

  PetFoodBowlPainter({
    required this.bowl,
    required this.bowlColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height * 0.40; // Center of bowl rim opening

    final double bowlWidth = size.width * 0.74; // ~210px
    final double bowlHeight = size.height * 0.52; // ~98px (taller, deeper 3D bowl!)
    final double openingRx = bowlWidth / 2;
    final double openingRy = bowlHeight * 0.26; // ~25px

    // 1. Base Shadow under bowl
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bowlHeight + 6),
        width: bowlWidth * 0.88,
        height: 22,
      ),
      shadowPaint,
    );

    // 2. Bowl Outer Body Path (Taller & Deeper Profile)
    final Path bowlBodyPath = Path();
    bowlBodyPath.moveTo(cx - openingRx, cy);
    bowlBodyPath.cubicTo(
      cx - openingRx * 0.90, cy + bowlHeight * 1.05,
      cx + openingRx * 0.90, cy + bowlHeight * 1.05,
      cx + openingRx, cy,
    );
    bowlBodyPath.close();

    // Fill Bowl Body using Dusty Olive Morandi Color Gradient
    final Paint bodyFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [bowlColor, _darkenColor(bowlColor, 0.22)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - openingRx, cy, bowlWidth, bowlHeight));
    canvas.drawPath(bowlBodyPath, bodyFillPaint);

    // Deep Warm Morandi Outline for Bowl Body
    final Paint outlinePaint = Paint()
      ..color = _darkenColor(bowlColor, 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawPath(bowlBodyPath, outlinePaint);

    // 3. Paw Print Emblem on Front
    _drawPawEmblem(canvas, Offset(cx, cy + bowlHeight * 0.52));

    // 4. Inner Bowl Cavity Ellipse (Slightly lighter warm grey-olive interior)
    final Rect openingRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: openingRx * 2,
      height: openingRy * 2,
    );

    final Paint cavityPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          _darkenColor(bowlColor, 0.14), // Lighter warm slate-grey center
          _darkenColor(bowlColor, 0.26), // Soft depth shadow towards rim
        ],
      ).createShader(openingRect);
    canvas.drawOval(openingRect, cavityPaint);

    // Inner Cavity Rim Stroke
    final Paint innerRimPaint = Paint()
      ..color = Colors.white.withAlpha(160) // Soft glossy rim highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(openingRect, innerRimPaint);

    // 5. Draw Food Pieces (Organic Kibble Mound inside bowl cavity)
    if (bowl.isNotEmpty) {
      final List<_KibblePiece> pieces = _generateKibbles(bowl, cx, cy, openingRx, openingRy);

      // Sort by Y position (back to front depth ordering)
      pieces.sort((a, b) => a.y.compareTo(b.y));

      for (var piece in pieces) {
        _drawKibblePiece(canvas, piece);
      }
    } else {
      // Empty bowl label inside cavity
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: "Bowl is empty",
          style: TextStyle(
            color: Colors.white.withAlpha(140),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    // 6. Draw Front Rim Lip over base food layer for realistic depth!
    final Path frontRimPath = Path();
    frontRimPath.addArc(openingRect, 0, 3.14159); // Bottom half of opening ellipse
    final Paint frontRimPaint = Paint()
      ..color = _darkenColor(bowlColor, 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawPath(frontRimPath, frontRimPaint);
  }

  void _drawPawEmblem(Canvas canvas, Offset center) {
    final Paint emblemPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.fill;

    // Main pad
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 3), width: 14, height: 11),
      emblemPaint,
    );
    // Toe pads
    canvas.drawCircle(Offset(center.dx - 8, center.dy - 4), 3, emblemPaint);
    canvas.drawCircle(Offset(center.dx - 3, center.dy - 8), 3, emblemPaint);
    canvas.drawCircle(Offset(center.dx + 3, center.dy - 8), 3, emblemPaint);
    canvas.drawCircle(Offset(center.dx + 8, center.dy - 4), 3, emblemPaint);
  }

  void _drawKibblePiece(Canvas canvas, _KibblePiece piece) {
    canvas.save();
    canvas.translate(piece.x, piece.y);
    canvas.rotate(piece.angle);

    final double rx = piece.width / 2;
    final double ry = piece.height / 2;
    final Rect kibbleRect = Rect.fromLTRB(-rx, -ry, rx, ry);

    // 3D fill gradient with specular highlight
    final Paint fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [piece.lightColor, piece.darkColor],
      ).createShader(kibbleRect);

    // Dark vector outline
    final Paint outlinePaint = Paint()
      ..color = piece.outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (piece.shape == _KibbleShape.oval) {
      canvas.drawOval(kibbleRect, fillPaint);
      canvas.drawOval(kibbleRect, outlinePaint);
    } else if (piece.shape == _KibbleShape.leaf) {
      final Path leafPath = Path();
      leafPath.moveTo(0, -ry);
      leafPath.quadraticBezierTo(rx * 1.2, -ry * 0.2, rx, ry * 0.8);
      leafPath.quadraticBezierTo(0, ry * 1.2, -rx, ry * 0.8);
      leafPath.quadraticBezierTo(-rx * 1.2, -ry * 0.2, 0, -ry);
      leafPath.close();

      canvas.drawPath(leafPath, fillPaint);
      canvas.drawPath(leafPath, outlinePaint);
    } else {
      // Sphere / Meatball kibble
      final RRect rrect = RRect.fromRectAndRadius(kibbleRect, Radius.circular(rx * 0.6));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, outlinePaint);
    }

    // Top highlight specular spot
    final Paint spotPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-rx * 0.3, -ry * 0.3), rx * 0.25, spotPaint);

    canvas.restore();
  }

  List<_KibblePiece> _generateKibbles(
    List<BowlIngredient> bowl,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    List<_KibblePiece> list = [];

    int globalPieceIndex = 0;

    for (var item in bowl) {
      final style = _getKibbleStyle(item.ingredient.category);

      // Number of kibbles based on mass (min 3, max 14 per ingredient)
      int numPieces = (item.massGrams / 15).ceil().clamp(3, 14);

      // Deterministic hash seed based on ingredient ID for position stability
      int seed = item.ingredient.ingredientId.hashCode;

      for (int i = 0; i < numPieces; i++) {
        // Pseudo-random deterministic offsets
        double pseudo1 = (((seed + i * 17) % 100) / 100.0) - 0.5;
        double pseudo2 = (((seed + i * 31) % 100) / 100.0) - 0.5;

        // Layer mounding logic
        int layer = i ~/ 4;
        
        double xOffset = (pseudo1 * 1.2 * rx) * (1.0 - (layer * 0.15));
        double yOffset = (pseudo2 * 0.6 * ry) - (layer * 9.0) + (globalPieceIndex % 3 == 0 ? -4 : 2);

        xOffset = xOffset.clamp(-rx * 0.8, rx * 0.8);

        double angle = (-0.35 + (((seed + i * 13) % 70) / 100.0));

        list.add(_KibblePiece(
          x: cx + xOffset,
          y: cy + yOffset,
          angle: angle,
          width: style.width,
          height: style.height,
          lightColor: style.lightColor,
          darkColor: style.darkColor,
          outlineColor: style.outlineColor,
          shape: style.shape,
        ));

        globalPieceIndex++;
      }
    }

    return list;
  }

  _KibbleStyle _getKibbleStyle(String category) {
    String c = category.toLowerCase();

    // 1. VEGETABLES / LEAFY (Broccoli, Carrots, Sweet Potato)
    if (c.contains('veg') || c.contains('green') || c.contains('leafy') || c.contains('broccoli')) {
      return const _KibbleStyle(
        lightColor: Color(0xFF66BB6A),
        darkColor: Color(0xFF2E7D32),
        outlineColor: Color(0xFF1B5E20),
        shape: _KibbleShape.leaf,
        width: 26,
        height: 18,
      );
    }

    // 2. POULTRY / CHICKEN / TURKEY
    if (c.contains('poultry') || c.contains('chicken') || c.contains('turkey')) {
      return const _KibbleStyle(
        lightColor: Color(0xFFFFA726),
        darkColor: Color(0xFFE65100),
        outlineColor: Color(0xFF8D4000),
        shape: _KibbleShape.oval,
        width: 28,
        height: 18,
      );
    }

    // 3. MEAT / BEEF / ORGAN MEAT
    if (c.contains('meat') || c.contains('beef') || c.contains('organ')) {
      return const _KibbleStyle(
        lightColor: Color(0xFF8D6E63),
        darkColor: Color(0xFF4E342E),
        outlineColor: Color(0xFF2C1B18),
        shape: _KibbleShape.sphere,
        width: 24,
        height: 20,
      );
    }

    // 4. FISH / SALMON
    if (c.contains('fish') || c.contains('salmon') || c.contains('seafood')) {
      return const _KibbleStyle(
        lightColor: Color(0xFFFF8A65),
        darkColor: Color(0xFFD84315),
        outlineColor: Color(0xFF801A00),
        shape: _KibbleShape.oval,
        width: 26,
        height: 16,
      );
    }

    // 5. PROTEIN / EGG
    if (c.contains('egg') || c.contains('protein')) {
      return const _KibbleStyle(
        lightColor: Color(0xFFFFE082),
        darkColor: Color(0xFFFFB300),
        outlineColor: Color(0xFFB27B00),
        shape: _KibbleShape.sphere,
        width: 22,
        height: 22,
      );
    }

    // 6. FRUIT / BERRY
    if (c.contains('fruit') || c.contains('berry')) {
      return const _KibbleStyle(
        lightColor: Color(0xFFEF9A9A),
        darkColor: Color(0xFFC62828),
        outlineColor: Color(0xFF7F0000),
        shape: _KibbleShape.sphere,
        width: 20,
        height: 20,
      );
    }

    // DEFAULT / GRAINS
    return const _KibbleStyle(
      lightColor: Color(0xFFFFCC80),
      darkColor: Color(0xFFFB8C00),
      outlineColor: Color(0xFF9E4700),
      shape: _KibbleShape.oval,
      width: 24,
      height: 16,
    );
  }

  Color _darkenColor(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  bool shouldRepaint(covariant PetFoodBowlPainter oldDelegate) => true;
}
