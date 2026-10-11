import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutritional_provider.dart';
import '../../services/recipe_service.dart';
import '../widgets/fringe_header.dart';
import 'nutrition_engine_screen.dart';

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});

  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _errorCoral = const Color(0xFFB56576);

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    final RecipeService recipeService = RecipeService();

    return Scaffold(
      backgroundColor: _drySage,
      body: Column(
        children: [
          FringeHeader(
            title: "Saved Recipes",
            subtitle: "Custom Meal Bowls Sync",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: uid.isEmpty
                ? const Center(child: Text("Please log in to view saved recipes.", style: TextStyle(color: Colors.white)))
                : StreamBuilder<List<SavedRecipe>>(
                    stream: recipeService.streamUserRecipes(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      final recipes = snapshot.data ?? [];

                      if (recipes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded, size: 64, color: Colors.white.withAlpha(120)),
                              const SizedBox(height: 16),
                              Text(
                                "No Saved Recipes Yet",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Build a balanced meal in the Nutrition Engine and tap 'Save Recipe' to see it here!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: recipes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: _powderPetal, shape: BoxShape.circle),
                                      child: Icon(Icons.restaurant_menu_rounded, color: _dustyOlive, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.recipeName,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${recipe.petName} • ${DateFormat('dd MMM yyyy, hh:mm a').format(recipe.createdAt)}",
                                            style: TextStyle(color: _ashGrey, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, color: _errorCoral, size: 20),
                                      onPressed: () async {
                                        await recipeService.deleteRecipe(uid, recipe.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Deleted '${recipe.recipeName}'")),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _desertSand.withAlpha(40),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${recipe.totalKcal.toInt()} kcal total",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _darkCharcoal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: recipe.ingredients.map((ing) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _powderPetal.withAlpha(120),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _dustyOlive.withAlpha(40)),
                                      ),
                                      child: Text(
                                        "${ing.ingredient.name} (${ing.massGrams.toInt()}g)",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkCharcoal),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final provider = Provider.of<NutritionalProvider>(context, listen: false);
                                      provider.clearBowl();
                                      for (var ing in recipe.ingredients) {
                                        provider.addIngredient(ing.ingredient, ing.massGrams);
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const NutritionEngineScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.soup_kitchen_rounded, size: 18, color: Colors.white),
                                    label: const Text("Load into Engine Bowl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _dustyOlive,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
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
}
