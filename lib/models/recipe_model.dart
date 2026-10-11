import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient_model.dart';

class SavedRecipe {
  final String id;
  final String petId;
  final String petName;
  final String recipeName;
  final DateTime createdAt;
  final double totalKcal;
  final List<BowlIngredient> ingredients;

  SavedRecipe({
    required this.id,
    required this.petId,
    required this.petName,
    required this.recipeName,
    required this.createdAt,
    required this.totalKcal,
    required this.ingredients,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'petName': petName,
      'recipeName': recipeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalKcal': totalKcal,
      'ingredients': ingredients.map((item) => {
        'ingredientId': item.ingredient.ingredientId,
        'name': item.ingredient.name,
        'category': item.ingredient.category,
        'massGrams': item.massGrams,
        'nutrientsPer100g': {
          'kcal': item.ingredient.nutrientsPer100g.kcal,
          'proteinGrams': item.ingredient.nutrientsPer100g.proteinGrams,
          'fatGrams': item.ingredient.nutrientsPer100g.fatGrams,
          'carbsGrams': item.ingredient.nutrientsPer100g.carbsGrams,
          'calciumMg': item.ingredient.nutrientsPer100g.calciumMg,
          'phosphorusMg': item.ingredient.nutrientsPer100g.phosphorusMg,
          'vitaminsGrams': item.ingredient.nutrientsPer100g.vitaminsGrams,
          'mineralsGrams': item.ingredient.nutrientsPer100g.mineralsGrams,
          'moistureGrams': item.ingredient.nutrientsPer100g.moistureGrams,
          'fiberGrams': item.ingredient.nutrientsPer100g.fiberGrams,
          'sodiumMg': item.ingredient.nutrientsPer100g.sodiumMg,
          'magnesiumMg': item.ingredient.nutrientsPer100g.magnesiumMg,
        },
      }).toList(),
    };
  }

  factory SavedRecipe.fromMap(Map<String, dynamic> map, String docId) {
    var rawIngredients = map['ingredients'] as List<dynamic>? ?? [];
    List<BowlIngredient> bowlList = rawIngredients.map((ingMap) {
      final ing = Ingredient.fromMap(ingMap as Map<String, dynamic>);
      return BowlIngredient(ingredient: ing, massGrams: (ingMap['massGrams'] as num?)?.toDouble() ?? 100.0);
    }).toList();

    return SavedRecipe(
      id: docId,
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? 'Pet',
      recipeName: map['recipeName'] ?? 'Custom Recipe',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalKcal: (map['totalKcal'] as num?)?.toDouble() ?? 0.0,
      ingredients: bowlList,
    );
  }
}
