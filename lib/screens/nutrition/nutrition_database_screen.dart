import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/ingredient_model.dart';
import '../../providers/nutritional_provider.dart';
import '../widgets/fringe_header.dart';

/// Category Palette & Style mapping strictly aligned with Pet Owner's Nutrition Engine
class _CategoryStyle {
  final Color mainColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  const _CategoryStyle({
    required this.mainColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });
}

_CategoryStyle _getCategoryStyle(String category, {bool isToxic = false}) {
  String c = category.trim().toLowerCase();

  if (isToxic || c.contains('toxic')) {
    return const _CategoryStyle(
      mainColor: Color(0xFFD32F2F),
      bgColor: Color(0xFFFFEBEE),
      borderColor: Color(0xFFEF5350),
      icon: Icons.warning_amber_rounded,
    );
  }

  if (c.contains('poultry')) {
    return const _CategoryStyle(
      mainColor: Color(0xFFD97724),
      bgColor: Color(0xFFFFF3E0),
      borderColor: Color(0xFFFCD3A1),
      icon: Icons.restaurant_rounded,
    );
  }

  if (c.contains('meat')) {
    return const _CategoryStyle(
      mainColor: Color(0xFF6D4C41),
      bgColor: Color(0xFFEFEBE9),
      borderColor: Color(0xFFA1887F),
      icon: Icons.pets_rounded,
    );
  }

  if (c.contains('organ')) {
    return const _CategoryStyle(
      mainColor: Color(0xFF5D4037),
      bgColor: Color(0xFFEFEBE9),
      borderColor: Color(0xFF8D6E63),
      icon: Icons.favorite_rounded,
    );
  }

  if (c.contains('fish') || c.contains('seafood')) {
    return const _CategoryStyle(
      mainColor: Color(0xFFE64A19),
      bgColor: Color(0xFFFBE9E7),
      borderColor: Color(0xFFFFAB91),
      icon: Icons.phishing_rounded,
    );
  }

  if (c.contains('veg')) {
    return const _CategoryStyle(
      mainColor: Color(0xFF2E7D32),
      bgColor: Color(0xFFE8F5E9),
      borderColor: Color(0xFF81C784),
      icon: Icons.eco_rounded,
    );
  }

  if (c.contains('fruit')) {
    return const _CategoryStyle(
      mainColor: Color(0xFF8E24AA),
      bgColor: Color(0xFFF3E5F5),
      borderColor: Color(0xFFE1BEE7),
      icon: Icons.apple_rounded,
    );
  }

  return const _CategoryStyle(
    mainColor: Color(0xFF386FA4),
    bgColor: Color(0xFFF4F7F6),
    borderColor: Color(0xFFBEE9E8),
    icon: Icons.restaurant_menu_rounded,
  );
}

/// NutritionDatabaseScreen: Displays full food & ingredient list strictly categorized
/// according to the Pet Owner's Nutrition Engine standards (Meat, Poultry, Organ, Fish and Seafood, Vegetable, Fruit, Toxic).
class NutritionDatabaseScreen extends StatefulWidget {
  const NutritionDatabaseScreen({super.key});

  @override
  State<NutritionDatabaseScreen> createState() => _NutritionDatabaseScreenState();
}

class _NutritionDatabaseScreenState extends State<NutritionDatabaseScreen> {
  // Theme Colors
  final Color _pacificBlue = const Color(0xFF386FA4);
  final Color _softBg = const Color(0xFFF4F7F6);
  final Color _darkText = const Color(0xFF2D3142);
  final Color _subText = const Color(0xFF6C757D);

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  // Strictly follow requested category filter list
  final List<String> _categories = [
    'All',
    'Meat',
    'Poultry',
    'Organ',
    'Fish and Seafood',
    'Vegetable',
    'Fruit',
    'Toxic',
  ];

  final List<String> _ingredientCategories = [
    'Meat',
    'Poultry',
    'Organ',
    'Fish and Seafood',
    'Vegetable',
    'Fruit',
    'Toxic',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NutritionalProvider>(context, listen: false).loadIngredients();
    });
  }

  /// Categorizes an ingredient into exactly ONE primary category for filtering
  String _getPrimaryCategory(Ingredient item) {
    final cat = item.category.trim().toLowerCase();
    final name = item.name.trim().toLowerCase();

    if (cat.contains('toxic') || item.isToxicToDogs || item.isToxicToCats) {
      return 'Toxic';
    }

    if (cat.contains('organ') ||
        name.contains('liver') ||
        name.contains('heart') ||
        name.contains('gizzard') ||
        name.contains('kidney') ||
        name.contains('tripe') ||
        name.contains('spleen')) {
      return 'Organ';
    }

    if (cat.contains('poultry') ||
        name.contains('chicken') ||
        name.contains('turkey') ||
        name.contains('duck') ||
        name.contains('quail') ||
        name.contains('egg')) {
      return 'Poultry';
    }

    if (cat.contains('meat') ||
        name.contains('beef') ||
        name.contains('pork') ||
        name.contains('lamb') ||
        name.contains('mutton') ||
        name.contains('venison')) {
      return 'Meat';
    }

    if (cat.contains('fish') ||
        cat.contains('seafood') ||
        name.contains('salmon') ||
        name.contains('mackerel') ||
        name.contains('tuna') ||
        name.contains('fish') ||
        name.contains('shrimp')) {
      return 'Fish and Seafood';
    }

    if (cat.contains('fruit') ||
        name.contains('berry') ||
        name.contains('blueberries') ||
        name.contains('apple') ||
        name.contains('banana') ||
        name.contains('watermelon') ||
        name.contains('strawberry') ||
        name.contains('cantaloupe') ||
        name.contains('papaya') ||
        name.contains('cranberries')) {
      return 'Fruit';
    }

    if (cat.contains('veg') ||
        name.contains('broccoli') ||
        name.contains('pumpkin') ||
        name.contains('carrot') ||
        name.contains('spinach') ||
        name.contains('sweet potato') ||
        name.contains('beans') ||
        name.contains('zucchini') ||
        name.contains('cucumber') ||
        name.contains('celery') ||
        name.contains('peas') ||
        name.contains('mushroom') ||
        name.contains('chickpeas')) {
      return 'Vegetable';
    }

    return item.category.isNotEmpty ? item.category : 'Meat';
  }

  bool _matchesCategory(Ingredient item, String filterCategory) {
    if (filterCategory == 'All') return true;
    final primaryCat = _getPrimaryCategory(item);
    return primaryCat.trim().toLowerCase() == filterCategory.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Nutrition Database",
            subtitle: "FOOD & NUTRIENT MANAGEMENT",
            backgroundColor: _pacificBlue,
            onBack: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Top Search Bar & Add Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          hintText: "Search ingredients by name...",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pacificBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      onPressed: () => _openIngredientModal(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        "Add Ingredient",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Chips Filter Bar
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      final catStyle = cat == 'All'
                          ? const _CategoryStyle(
                              mainColor: Color(0xFF386FA4),
                              bgColor: Color(0xFFF4F7F6),
                              borderColor: Color(0xFF386FA4),
                              icon: Icons.all_inclusive_rounded,
                            )
                          : _getCategoryStyle(cat);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            catStyle.icon,
                            size: 16,
                            color: isSelected ? Colors.white : catStyle.mainColor,
                          ),
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: catStyle.mainColor,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _darkText,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? catStyle.mainColor : Colors.grey.shade300,
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Ingredient List (Merged Offline Engine Ingredients + Firestore Custom Items)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('INGREDIENTS').snapshots(),
              builder: (context, snapshot) {
                final firestoreDocs = snapshot.data?.docs ?? [];
                final customIngredients = firestoreDocs.map((doc) {
                  final data = doc.data();
                  data['ingredientId'] = doc.id;
                  return Ingredient.fromJson(data);
                }).toList();

                final provider = Provider.of<NutritionalProvider>(context);
                final Map<String, Ingredient> mergedMap = {};

                // 1. Add offline base engine ingredients
                for (var ing in provider.allIngredients) {
                  mergedMap[ing.ingredientId] = ing;
                }

                // 2. Override/add Firestore custom ingredients
                for (var customIng in customIngredients) {
                  mergedMap[customIng.ingredientId] = customIng;
                }

                List<Ingredient> list = mergedMap.values.toList();

                // Apply text search
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  list = list.where((i) => i.name.toLowerCase().contains(query)).toList();
                }

                // Apply category filter
                list = list.where((i) => _matchesCategory(i, _selectedCategory)).toList();

                // Sort alphabetically
                list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No ingredients found in '$_selectedCategory'",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap '+ Add Ingredient' above to create a new nutrient record.",
                          style: TextStyle(fontSize: 12, color: _subText),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isCustom = firestoreDocs.any((doc) => doc.id == item.ingredientId);
                    final primaryCat = _getPrimaryCategory(item);
                    final catStyle = _getCategoryStyle(
                      primaryCat,
                      isToxic: item.isToxicToDogs || item.isToxicToCats,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: catStyle.borderColor.withAlpha(180), width: 1.2),
                      ),
                      elevation: 1.5,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: catStyle.bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: catStyle.borderColor),
                                  ),
                                  child: Icon(
                                    catStyle.icon,
                                    color: catStyle.mainColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: _darkText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCustom)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.shade700, width: 0.8),
                                              ),
                                              child: Text(
                                                "Custom",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: catStyle.bgColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          primaryCat,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: catStyle.mainColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isCustom) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                    tooltip: "Edit Ingredient",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _openIngredientModal(existing: item),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                    tooltip: "Delete Ingredient",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Species Safety Badges
                            Row(
                              children: [
                                _buildSpeciesBadge("Dog", item.safeForDogs, item.isToxicToDogs),
                                const SizedBox(width: 8),
                                _buildSpeciesBadge("Cat", item.safeForCats, item.isToxicToCats),
                                const Spacer(),
                                Text(
                                  "Per 100g",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Complete 100g Nutrients Grid Box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: catStyle.bgColor.withAlpha(120),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: catStyle.borderColor.withAlpha(100)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildNutrientStat("Calories", "${item.kcalPer100g.toStringAsFixed(0)} kcal"),
                                      _buildNutrientStat("Protein", "${item.proteinGrams.toStringAsFixed(1)} g"),
                                      _buildNutrientStat("Fat", "${item.fatGrams.toStringAsFixed(1)} g"),
                                      _buildNutrientStat("Carbs", "${item.carbsGrams.toStringAsFixed(1)} g"),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildNutrientStat("Fiber", "${item.fiberGrams.toStringAsFixed(1)} g"),
                                      _buildNutrientStat("Moisture", "${item.moistureGrams.toStringAsFixed(1)} g"),
                                      _buildNutrientStat("Calcium", "${item.calciumMg.toStringAsFixed(0)} mg"),
                                      _buildNutrientStat("Vitamins", "${item.vitaminsMg.toStringAsFixed(1)} mg"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesBadge(String label, bool isSafe, bool isToxic) {
    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    String text;

    if (isToxic) {
      bg = Colors.red.shade50;
      border = Colors.red.shade300;
      iconColor = Colors.red.shade700;
      icon = Icons.warning_amber_rounded;
      text = "$label: Toxic";
    } else if (isSafe) {
      bg = Colors.green.shade50;
      border = Colors.green.shade300;
      iconColor = Colors.green.shade700;
      icon = Icons.check_circle_outline_rounded;
      text = "$label: Safe";
    } else {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade300;
      iconColor = Colors.orange.shade700;
      icon = Icons.remove_circle_outline_rounded;
      text = "$label: Avoid";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientStat(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 9, color: _subText, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkText),
        ),
      ],
    );
  }

  // Confirm deletion dialog
  void _confirmDelete(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            const Text("Delete Ingredient", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${ingredient.name}' from the Firestore database? This action cannot be undone.",
          style: TextStyle(fontSize: 13, color: _darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final provider = Provider.of<NutritionalProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('INGREDIENTS')
                    .doc(ingredient.ingredientId)
                    .delete();

                provider.loadIngredients();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("Deleted '${ingredient.name}' successfully."),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text("Error deleting ingredient: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Open Modal Sheet to Add / Edit Ingredient
  void _openIngredientModal({Ingredient? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedCat = existing != null ? _getPrimaryCategory(existing) : 'Poultry';

    bool safeDogs = existing?.safeForDogs ?? true;
    bool safeCats = existing?.safeForCats ?? true;
    bool toxicDogs = existing?.isToxicToDogs ?? false;
    bool toxicCats = existing?.isToxicToCats ?? false;

    final kcalCtrl = TextEditingController(text: existing?.kcalPer100g.toString() ?? '0');
    final proteinCtrl = TextEditingController(text: existing?.proteinGrams.toString() ?? '0');
    final fatCtrl = TextEditingController(text: existing?.fatGrams.toString() ?? '0');
    final carbsCtrl = TextEditingController(text: existing?.carbsGrams.toString() ?? '0');
    final fiberCtrl = TextEditingController(text: existing?.fiberGrams.toString() ?? '0');
    final moistureCtrl = TextEditingController(text: existing?.moistureGrams.toString() ?? '0');
    final calciumCtrl = TextEditingController(text: existing?.calciumMg.toString() ?? '0');
    final vitCtrl = TextEditingController(text: existing?.vitaminsMg.toString() ?? '0');
    final minCtrl = TextEditingController(text: existing?.mineralsMg.toString() ?? '0');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final catStyle = _getCategoryStyle(selectedCat, isToxic: toxicDogs || toxicCats);

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            existing == null ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded,
                            color: _pacificBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              existing == null ? "Add New Ingredient" : "Edit Ingredient",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _darkText,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Input 100g nutritional profile values to save directly to Firebase.",
                        style: TextStyle(fontSize: 11, color: _subText),
                      ),
                      const SizedBox(height: 16),

                      // Ingredient Name
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(fontSize: 13, color: _darkText),
                        decoration: InputDecoration(
                          labelText: "Ingredient Name *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          hintText: "e.g., Raw Beef Kidney, Cooked Salmon, Pumpkin Puree",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown (Strict Engine Standards)
                      DropdownButtonFormField<String>(
                        initialValue: selectedCat,
                        isExpanded: true,
                        style: TextStyle(fontSize: 13, color: _darkText, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: "Category (Engine Standard) *",
                          labelStyle: TextStyle(fontSize: 12, color: _subText),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _ingredientCategories
                            .map((c) {
                              final style = _getCategoryStyle(c);
                              return DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(style.icon, size: 18, color: style.mainColor),
                                    const SizedBox(width: 8),
                                    Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedCat = val;
                              if (val == 'Toxic') {
                                safeDogs = false;
                                safeCats = false;
                                toxicDogs = true;
                                toxicCats = true;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Species Safety Switches
                      Text(
                        "SPECIES SAFETY & TOXICITY",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: catStyle.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: catStyle.borderColor),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Safe for Dogs", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              subtitle: Text(safeDogs ? "Suitable for dog diets" : "Unsuitable for dogs", style: const TextStyle(fontSize: 10)),
                              value: safeDogs,
                              activeThumbColor: Colors.green,
                              onChanged: (val) {
                                setSheetState(() {
                                  safeDogs = val;
                                  if (val) toxicDogs = false;
                                });
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Toxic to Dogs", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                              subtitle: const Text("Triggers clinical warnings for dogs (e.g. Onion/Garlic/Chocolate)", style: TextStyle(fontSize: 10)),
                              value: toxicDogs,
                              activeThumbColor: Colors.red,
                              onChanged: (val) {
                                setSheetState(() {
                                  toxicDogs = val;
                                  if (val) safeDogs = false;
                                });
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Safe for Cats", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              subtitle: Text(safeCats ? "Suitable for cat diets" : "Unsuitable for cats", style: const TextStyle(fontSize: 10)),
                              value: safeCats,
                              activeThumbColor: Colors.green,
                              onChanged: (val) {
                                setSheetState(() {
                                  safeCats = val;
                                  if (val) toxicCats = false;
                                });
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Toxic to Cats", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                              subtitle: const Text("Triggers clinical warnings for cats", style: TextStyle(fontSize: 10)),
                              value: toxicCats,
                              activeThumbColor: Colors.red,
                              onChanged: (val) {
                                setSheetState(() {
                                  toxicCats = val;
                                  if (val) safeCats = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nutrients per 100g Section
                      Text(
                        "NUTRIENTS PER 100g SERVING",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _subText, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(child: _buildModalNumField("Calories (kcal)", kcalCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalNumField("Protein (g)", proteinCtrl)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildModalNumField("Fat (g)", fatCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalNumField("Carbs (g)", carbsCtrl)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildModalNumField("Fiber (g)", fiberCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalNumField("Moisture (g)", moistureCtrl)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildModalNumField("Calcium (mg)", calciumCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalNumField("Vitamins (mg)", vitCtrl)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildModalNumField("Minerals (mg)", minCtrl)),
                          const SizedBox(width: 8),
                          const Expanded(child: SizedBox()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.pop(context);
                                    },
                              child: Text("Cancel", style: TextStyle(color: _darkText, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: catStyle.mainColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();

                                      final name = nameCtrl.text.trim();
                                      if (name.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please enter an Ingredient Name.")),
                                        );
                                        return;
                                      }

                                      setSheetState(() => isSaving = true);

                                      final docId = existing?.ingredientId ?? "ING_${DateTime.now().millisecondsSinceEpoch}";

                                      final double kcal = double.tryParse(kcalCtrl.text.trim()) ?? 0.0;
                                      final double protein = double.tryParse(proteinCtrl.text.trim()) ?? 0.0;
                                      final double fat = double.tryParse(fatCtrl.text.trim()) ?? 0.0;
                                      final double carbs = double.tryParse(carbsCtrl.text.trim()) ?? 0.0;
                                      final double fiber = double.tryParse(fiberCtrl.text.trim()) ?? 0.0;
                                      final double moisture = double.tryParse(moistureCtrl.text.trim()) ?? 0.0;
                                      final double calcium = double.tryParse(calciumCtrl.text.trim()) ?? 0.0;
                                      final double vit = double.tryParse(vitCtrl.text.trim()) ?? 0.0;
                                      final double min = double.tryParse(minCtrl.text.trim()) ?? 0.0;

                                      final newIngredient = Ingredient(
                                        ingredientId: docId,
                                        name: name,
                                        category: selectedCat,
                                        safeForDogs: safeDogs,
                                        safeForCats: safeCats,
                                        isToxicToDogs: toxicDogs,
                                        isToxicToCats: toxicCats,
                                        kcalPer100g: kcal,
                                        proteinGrams: protein,
                                        fatGrams: fat,
                                        carbsGrams: carbs,
                                        fiberGrams: fiber,
                                        moistureGrams: moisture,
                                        calciumMg: calcium,
                                        vitaminsMg: vit,
                                        mineralsMg: min,
                                      );

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('INGREDIENTS')
                                            .doc(docId)
                                            .set(newIngredient.toJson());

                                        if (context.mounted) {
                                          Provider.of<NutritionalProvider>(context, listen: false).loadIngredients();
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Successfully saved '$name' to Firebase!"),
                                              backgroundColor: Colors.green.shade700,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setSheetState(() => isSaving = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error saving ingredient: $e")),
                                          );
                                        }
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      existing == null ? "Save to Firebase" : "Update Ingredient",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalNumField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: 12, color: _darkText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: _subText),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
