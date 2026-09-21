class Nutrients {
  final double kcal;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double calciumMg;
  final double phosphorusMg;
  final double vitaminsGrams; // Added for UI progress bars
  final double mineralsGrams; // Added for UI progress bars
  final double moistureGrams;

  Nutrients({
    required this.kcal,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.calciumMg,
    required this.phosphorusMg,
    required this.vitaminsGrams,
    required this.mineralsGrams,
    required this.moistureGrams,
  });

  factory Nutrients.fromMap(Map<String, dynamic> map) {
    return Nutrients(
      kcal: (map['kcal'] ?? 0.0).toDouble(),
      proteinGrams: (map['proteinGrams'] ?? 0.0).toDouble(),
      fatGrams: (map['fatGrams'] ?? 0.0).toDouble(),
      carbsGrams: (map['carbsGrams'] ?? 0.0).toDouble(),
      calciumMg: (map['calciumMg'] ?? 0.0).toDouble(),
      phosphorusMg: (map['phosphorusMg'] ?? 0.0).toDouble(),
      vitaminsGrams: (map['vitaminsGrams'] ?? 0.0).toDouble(),
      mineralsGrams: (map['mineralsGrams'] ?? 0.0).toDouble(),
      moistureGrams: (map['moistureGrams'] ?? 0.0).toDouble(),
    );
  }

  Nutrients scale(double grams) {
    double factor = grams / 100.0;
    return Nutrients(
      kcal: kcal * factor,
      proteinGrams: proteinGrams * factor,
      fatGrams: fatGrams * factor,
      carbsGrams: carbsGrams * factor,
      calciumMg: calciumMg * factor,
      phosphorusMg: phosphorusMg * factor,
      vitaminsGrams: vitaminsGrams * factor,
      mineralsGrams: mineralsGrams * factor,
      moistureGrams: moistureGrams * factor,
    );
  }
}

class Ingredient {
  final String ingredientId;
  final String name;
  final String category;
  final bool safeForDogs;
  final bool safeForCats;
  final bool isToxicToDogs; // Added for safety interceptor
  final bool isToxicToCats; // Added for safety interceptor
  final Nutrients nutrientsPer100g;
  final List<String> allergenTags;

  Ingredient({
    required this.ingredientId,
    required this.name,
    required this.category,
    required this.safeForDogs,
    required this.safeForCats,
    this.isToxicToDogs = false,
    this.isToxicToCats = false,
    required this.nutrientsPer100g,
    required this.allergenTags,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      ingredientId: map['ingredientId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      safeForDogs: map['safeForDogs'] ?? true,
      safeForCats: map['safeForCats'] ?? true,
      isToxicToDogs: map['isToxicToDogs'] ?? false,
      isToxicToCats: map['isToxicToCats'] ?? false,
      nutrientsPer100g: Nutrients.fromMap(map['nutrientsPer100g'] ?? {}),
      allergenTags: List<String>.from(map['allergenTags'] ?? []),
    );
  }
}

class BowlIngredient {
  final Ingredient ingredient;
  final double massGrams;

  BowlIngredient({
    required this.ingredient,
    required this.massGrams,
  });

  Nutrients get scaledNutrients => ingredient.nutrientsPer100g.scale(massGrams);
}
