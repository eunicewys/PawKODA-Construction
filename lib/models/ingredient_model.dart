class Nutrients {
  final double kcal;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double calciumMg;
  final double phosphorusMg;
  final double vitaminsGrams;
  final double mineralsGrams;
  final double moistureGrams;
  final double fiberGrams;
  final double sodiumMg;
  final double magnesiumMg;

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
    this.fiberGrams = 0.0,
    this.sodiumMg = 0.0,
    this.magnesiumMg = 0.0,
  });

  factory Nutrients.fromMap(Map<String, dynamic> map) {
    return Nutrients(
      kcal: (map['kcalPer100g'] ?? map['kcal'] ?? 0.0).toDouble(),
      proteinGrams: (map['proteinGrams'] ?? 0.0).toDouble(),
      fatGrams: (map['fatGrams'] ?? 0.0).toDouble(),
      carbsGrams: (map['carbsGrams'] ?? 0.0).toDouble(),
      calciumMg: (map['calciumMg'] ?? 0.0).toDouble(),
      phosphorusMg: (map['phosphorusMg'] ?? 0.0).toDouble(),
      vitaminsGrams: (map['vitaminsGrams'] ?? map['vitaminsMg'] ?? 0.0).toDouble(),
      mineralsGrams: (map['mineralsGrams'] ?? map['mineralsMg'] ?? 0.0).toDouble(),
      moistureGrams: (map['moistureGrams'] ?? 0.0).toDouble(),
      fiberGrams: (map['fiberGrams'] ?? 0.0).toDouble(),
      sodiumMg: (map['sodiumMg'] ?? 0.0).toDouble(),
      magnesiumMg: (map['magnesiumMg'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kcal': kcal,
      'proteinGrams': proteinGrams,
      'fatGrams': fatGrams,
      'carbsGrams': carbsGrams,
      'calciumMg': calciumMg,
      'phosphorusMg': phosphorusMg,
      'vitaminsGrams': vitaminsGrams,
      'mineralsGrams': mineralsGrams,
      'moistureGrams': moistureGrams,
      'fiberGrams': fiberGrams,
      'sodiumMg': sodiumMg,
      'magnesiumMg': magnesiumMg,
    };
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
      fiberGrams: fiberGrams * factor,
      sodiumMg: sodiumMg * factor,
      magnesiumMg: magnesiumMg * factor,
    );
  }
}

class Ingredient {
  final String ingredientId;
  final String name;
  final String category;
  final bool safeForDogs;
  final bool safeForCats;
  final bool isToxicToDogs;
  final bool isToxicToCats;
  final double kcalPer100g;
  final double proteinGrams;
  final double fatGrams;
  final double carbsGrams;
  final double fiberGrams;
  final double moistureGrams;
  final double calciumMg;
  final double vitaminsMg;
  final double mineralsMg;
  final List<String> allergenTags;
  final Nutrients nutrientsPer100g;

  Ingredient({
    required this.ingredientId,
    required this.name,
    required this.category,
    required this.safeForDogs,
    required this.safeForCats,
    this.isToxicToDogs = false,
    this.isToxicToCats = false,
    double? kcalPer100g,
    double? proteinGrams,
    double? fatGrams,
    double? carbsGrams,
    double? fiberGrams,
    double? moistureGrams,
    double? calciumMg,
    double? vitaminsMg,
    double? mineralsMg,
    this.allergenTags = const [],
    Nutrients? nutrientsPer100g,
  })  : nutrientsPer100g = nutrientsPer100g ??
            Nutrients(
              kcal: kcalPer100g ?? 0.0,
              proteinGrams: proteinGrams ?? 0.0,
              fatGrams: fatGrams ?? 0.0,
              carbsGrams: carbsGrams ?? 0.0,
              calciumMg: calciumMg ?? 0.0,
              phosphorusMg: 0.0,
              vitaminsGrams: vitaminsMg ?? 0.0,
              mineralsGrams: mineralsMg ?? 0.0,
              moistureGrams: moistureGrams ?? 0.0,
              fiberGrams: fiberGrams ?? 0.0,
            ),
        kcalPer100g = kcalPer100g ?? nutrientsPer100g?.kcal ?? 0.0,
        proteinGrams = proteinGrams ?? nutrientsPer100g?.proteinGrams ?? 0.0,
        fatGrams = fatGrams ?? nutrientsPer100g?.fatGrams ?? 0.0,
        carbsGrams = carbsGrams ?? nutrientsPer100g?.carbsGrams ?? 0.0,
        fiberGrams = fiberGrams ?? nutrientsPer100g?.fiberGrams ?? 0.0,
        moistureGrams = moistureGrams ?? nutrientsPer100g?.moistureGrams ?? 0.0,
        calciumMg = calciumMg ?? nutrientsPer100g?.calciumMg ?? 0.0,
        vitaminsMg = vitaminsMg ?? nutrientsPer100g?.vitaminsGrams ?? 0.0,
        mineralsMg = mineralsMg ?? nutrientsPer100g?.mineralsGrams ?? 0.0;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    bool safeDogs = json['safeForDogs'] ?? true;
    bool safeCats = json['safeForCats'] ?? true;
    bool toxicDogs = json['isToxicToDogs'] ?? (!safeDogs);
    bool toxicCats = json['isToxicToCats'] ?? (!safeCats);

    var nutData = (json['nutrientsPer100g'] as Map<String, dynamic>?) ?? json;
    double kcal = (json['kcalPer100g'] ?? nutData['kcal'] ?? 0.0).toDouble();
    double protein = (json['proteinGrams'] ?? nutData['proteinGrams'] ?? 0.0).toDouble();
    double fat = (json['fatGrams'] ?? nutData['fatGrams'] ?? 0.0).toDouble();
    double carbs = (json['carbsGrams'] ?? nutData['carbsGrams'] ?? 0.0).toDouble();
    double fiber = (json['fiberGrams'] ?? nutData['fiberGrams'] ?? 0.0).toDouble();
    double moisture = (json['moistureGrams'] ?? nutData['moistureGrams'] ?? 0.0).toDouble();
    double calcium = (json['calciumMg'] ?? nutData['calciumMg'] ?? 0.0).toDouble();
    double vit = (json['vitaminsMg'] ?? nutData['vitaminsGrams'] ?? 0.0).toDouble();
    double min = (json['mineralsMg'] ?? nutData['mineralsGrams'] ?? 0.0).toDouble();

    return Ingredient(
      ingredientId: (json['ingredientId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
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
      allergenTags: List<String>.from(json['allergenTags'] ?? []),
      nutrientsPer100g: Nutrients.fromMap(nutData),
    );
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'ingredientId': ingredientId,
      'name': name,
      'category': category,
      'safeForDogs': safeForDogs,
      'safeForCats': safeForCats,
      'isToxicToDogs': isToxicToDogs,
      'isToxicToCats': isToxicToCats,
      'kcalPer100g': kcalPer100g,
      'proteinGrams': proteinGrams,
      'fatGrams': fatGrams,
      'carbsGrams': carbsGrams,
      'fiberGrams': fiberGrams,
      'moistureGrams': moistureGrams,
      'calciumMg': calciumMg,
      'vitaminsMg': vitaminsMg,
      'mineralsMg': mineralsMg,
      'allergenTags': allergenTags,
      'nutrientsPer100g': nutrientsPer100g.toMap(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
}

typedef IngredientModel = Ingredient;

class BowlIngredient {
  final Ingredient ingredient;
  final double massGrams;

  BowlIngredient({
    required this.ingredient,
    required this.massGrams,
  });

  Nutrients get scaledNutrients => ingredient.nutrientsPer100g.scale(massGrams);
}

typedef SelectedIngredient = BowlIngredient;
