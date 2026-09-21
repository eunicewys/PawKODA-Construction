import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/ingredient_model.dart';
import '../../providers/nutritional_provider.dart';
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
      provider.addIngredient(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NutritionalProvider>();
    final pet = provider.selectedPet;

    if (pet == null) return const Scaffold(body: Center(child: Text("No pet selected")));

    return Scaffold(
      backgroundColor: _powderPetal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _darkCharcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nutrition Engine", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("${pet.name.toUpperCase()} • ${pet.breed.toUpperCase()}", style: TextStyle(color: _ashGrey, fontSize: 10)),
          ],
        ),
      ),
      body: SingleChildScrollView(
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

            // 3. MEAL PORTION SLIDER
            _buildMassSlider(provider),
            const SizedBox(height: 32),

            // 4. NUTRIENT ANALYSIS PROGRESS BARS
            _buildNutrientAnalysis(provider),
            const SizedBox(height: 32),

            // 5 & 6. TOTAL CALORIES & STATUS BANNER
            _buildCaloricDisplay(provider),
            const SizedBox(height: 32),

            // 7. ADD INGREDIENTS SECTION
            _buildAddIngredientsSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMetabolicHeader(PetProfile pet, NutritionalProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _dustyOlive,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _dustyOlive.withAlpha(60), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("METABOLIC PROFILE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _profileStat("Met. Weight", "${pet.weightKg} kg"),
              _profileStat("Age", "${(pet.ageInMonths / 12).toStringAsFixed(1)} yrs"),
              _profileStat("Activity", pet.activityLevel.name.toUpperCase()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _bigStatBox("RER (Resting)", "${provider.currentRER.toInt()} kcal/day")),
              const SizedBox(width: 12),
              Expanded(child: _bigStatBox("DER (Daily Target)", "${provider.targetDER.toInt()} kcal/day")),
            ],
          ),
        ],
      ),
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

  Widget _bigStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildFeedingBowl(NutritionalProvider provider) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)]),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visual Bowl Placeholder
          Image.network("https://cdn-icons-png.flaticon.com/512/3047/3047120.png", height: 120, color: _ashGrey.withAlpha(100)),
          Positioned(
            bottom: 20,
            child: Wrap(
              spacing: 8,
              children: provider.bowl.map((item) => Chip(
                label: Text(item.ingredient.name, style: TextStyle(fontSize: 10, color: _dustyOlive)),
                backgroundColor: _powderPetal,
                onDeleted: () => provider.removeIngredient(item.ingredient.ingredientId),
              )).toList(),
            ),
          ),
          if (provider.bowl.isEmpty)
            Text("Bowl is empty. Add ingredients below!", style: TextStyle(color: _ashGrey, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMassSlider(NutritionalProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Meal Portion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
              Text("${provider.mealMassGrams.toInt()}g", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: _dustyOlive)),
            ],
          ),
          Slider(
            value: provider.mealMassGrams,
            min: 50,
            max: 500,
            divisions: 45,
            activeColor: _dustyOlive,
            inactiveColor: _ashGrey.withAlpha(100),
            onChanged: (val) => provider.setMealMass(val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("50g (min)", style: TextStyle(color: _ashGrey, fontSize: 10)),
              Text("Rec: ~${(provider.targetDER / 3 / 1.2).toInt()}g/meal", style: TextStyle(color: _dustyOlive, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("500g (max)", style: TextStyle(color: _ashGrey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text("TOTAL CALORIES ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            Text("${provider.totalNutrients.kcal.toInt()} kcal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        CaloricStatusBanner(status: provider.adequacyStatus, petName: provider.selectedPet?.name ?? "Pet"),
      ],
    );
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
