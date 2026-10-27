import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';
import '../models/ingredient_model.dart';
import '../models/disease_model.dart';
import '../services/nutrition_calculator_service.dart';

/// NutritionalProvider: State management provider for pet selection, offline ingredient searching,
/// live multi-nutrient bowl aggregation, and clinical safety validations.
class NutritionalProvider extends ChangeNotifier {
  final NutritionCalculatorService _calculator = NutritionCalculatorService();

  // State Properties
  PetProfile? _currentPet;
  int _mealsPerDay = 1; // 1, 2, or 3 meals per day
  List<Ingredient> _allIngredients = [];
  List<Ingredient> _searchResults = [];
  List<BowlIngredient> _bowlIngredients = [];
  double _targetDER = 0.0;
  List<String> _clinicalWarnings = [];

  // Cumulative Nutrient Totals
  double _totalKcal = 0.0;
  double _totalProteinGrams = 0.0;
  double _totalFatGrams = 0.0;
  double _totalCalciumMg = 0.0;
  double _totalVitaminsMg = 0.0;
  double _totalMineralsMg = 0.0;
  double _totalCarbsGrams = 0.0;
  double _totalFiberGrams = 0.0;
  double _totalMoistureGrams = 0.0;
  double _totalPhosphorusMg = 0.0;
  double _totalSodiumMg = 0.0;
  double _totalMagnesiumMg = 0.0;

  // -----------------------------------------------------------------
  // REACTIVE LIFECYCLE & INGREDIENT SEARCH METHODS
  // -----------------------------------------------------------------

  /// Reads assets/data/ingredients.json and Firestore INGREDIENTS and populates _allIngredients
  Future<void> loadIngredients() async {
    try {
      List<Ingredient> loadedList = [];

      // 1. Load offline base ingredients
      try {
        final String response = await rootBundle.loadString('assets/data/ingredients.json');
        final List<dynamic> data = json.decode(response) as List<dynamic>;
        loadedList = data.map((i) => Ingredient.fromJson(i as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint("Error loading offline ingredients.json in NutritionalProvider: $e");
      }

      // 2. Load Firestore custom ingredients
      try {
        final snapshot = await FirebaseFirestore.instance.collection('INGREDIENTS').get();
        final firebaseIngredients = snapshot.docs.map((doc) {
          final data = doc.data();
          data['ingredientId'] = doc.id;
          return Ingredient.fromJson(data);
        }).toList();

        for (var customIng in firebaseIngredients) {
          int existingIdx = loadedList.indexWhere((i) => i.ingredientId == customIng.ingredientId || i.name.toLowerCase() == customIng.name.toLowerCase());
          if (existingIdx >= 0) {
            loadedList[existingIdx] = customIng;
          } else {
            loadedList.add(customIng);
          }
        }
      } catch (e) {
        debugPrint("Error fetching Firestore INGREDIENTS in NutritionalProvider: $e");
      }

      // Sort ingredients alphabetically A-Z
      loadedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _allIngredients = loadedList;
      _searchResults = List.from(_allIngredients);
      notifyListeners();
    } catch (e) {
      debugPrint("Error in loadIngredients: $e");
    }
  }

  /// Filters _allIngredients by query string
  void searchIngredients(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _searchResults = List.from(_allIngredients);
    } else {
      _searchResults = _allIngredients.where((i) {
        bool matchesName = i.name.toLowerCase().contains(q);
        bool matchesCategory = i.category.toLowerCase().contains(q);
        return matchesName || matchesCategory;
      }).toList();
    }

    _searchResults.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  /// Updates active pet profile and recalculates target DER & bowl state
  void setPet(PetProfile pet) {
    _currentPet = pet;
    _targetDER = _calculator.calculateTargetDER(pet);
    _bowlIngredients = []; // Reset bowl when pet changes
    if (_allIngredients.isEmpty) {
      loadIngredients();
    } else {
      searchIngredients("");
    }
    recalculateNutrients();
  }

  /// Alias for backward compatibility with existing screen callers
  void setSelectedPet(PetProfile pet) => setPet(pet);

  /// Allows dynamically updating disease / BCS in local state during engine simulation
  void updatePetDisease(DiseaseType disease, {int? bcs}) {
    if (_currentPet == null) return;
    _currentPet = _currentPet!.copyWith(
      healthCondition: disease == DiseaseType.none ? "Healthy" : "Needs Attention",
      isHealthy: disease == DiseaseType.none ? true : false,
      activeDisease: disease,
      bodyConditionScore: bcs ?? _currentPet!.bodyConditionScore,
    );
    _targetDER = _calculator.calculateTargetDER(_currentPet!);
    recalculateNutrients();
  }

  /// Adds an ingredient or updates its mass if already present in the bowl
  void addIngredient(Ingredient ingredient, double initialGrams) {
    if (_currentPet == null || initialGrams <= 0) return;

    int existingIndex = _bowlIngredients.indexWhere(
      (item) => item.ingredient.ingredientId == ingredient.ingredientId,
    );

    if (existingIndex >= 0) {
      _bowlIngredients[existingIndex] = BowlIngredient(
        ingredient: ingredient,
        massGrams: initialGrams,
      );
    } else {
      _bowlIngredients.add(BowlIngredient(
        ingredient: ingredient,
        massGrams: initialGrams,
      ));
    }
    recalculateNutrients();
  }

  /// Removes an ingredient from the bowl by index
  void removeIngredient(int index) {
    if (index >= 0 && index < _bowlIngredients.length) {
      _bowlIngredients.removeAt(index);
      recalculateNutrients();
    }
  }

  /// Removes an ingredient from the bowl by ID
  void removeIngredientById(String ingredientId) {
    _bowlIngredients.removeWhere((item) => item.ingredient.ingredientId == ingredientId);
    recalculateNutrients();
  }

  /// Updates the mass in grams for an ingredient at the given index
  void updateIngredientGrams(int index, double newGrams) {
    if (index >= 0 && index < _bowlIngredients.length) {
      if (newGrams <= 0) {
        _bowlIngredients.removeAt(index);
      } else {
        _bowlIngredients[index] = BowlIngredient(
          ingredient: _bowlIngredients[index].ingredient,
          massGrams: newGrams,
        );
      }
      recalculateNutrients();
    }
  }

  /// Clears all ingredients from the bowl
  void clearBowl() {
    _bowlIngredients = [];
    recalculateNutrients();
  }

  /// Multi-Nutrient Aggregation & Clinical Validation
  void recalculateNutrients() {
    _totalKcal = 0.0;
    _totalProteinGrams = 0.0;
    _totalFatGrams = 0.0;
    _totalCalciumMg = 0.0;
    _totalVitaminsMg = 0.0;
    _totalMineralsMg = 0.0;
    _totalCarbsGrams = 0.0;
    _totalFiberGrams = 0.0;
    _totalMoistureGrams = 0.0;
    _totalPhosphorusMg = 0.0;
    _totalSodiumMg = 0.0;
    _totalMagnesiumMg = 0.0;

    for (var item in _bowlIngredients) {
      double factor = item.massGrams / 100.0;
      _totalKcal += item.ingredient.kcalPer100g * factor;
      _totalProteinGrams += item.ingredient.proteinGrams * factor;
      _totalFatGrams += item.ingredient.fatGrams * factor;
      _totalCalciumMg += item.ingredient.calciumMg * factor;
      _totalVitaminsMg += item.ingredient.vitaminsMg * factor; // Accurately sums vitamins
      _totalMineralsMg += item.ingredient.mineralsMg * factor; // Accurately sums minerals
      _totalCarbsGrams += item.ingredient.carbsGrams * factor;
      _totalFiberGrams += item.ingredient.fiberGrams * factor;
      _totalMoistureGrams += item.ingredient.moistureGrams * factor;
      _totalPhosphorusMg += item.ingredient.nutrientsPer100g.phosphorusMg * factor;
      _totalSodiumMg += item.ingredient.nutrientsPer100g.sodiumMg * factor;
      _totalMagnesiumMg += item.ingredient.nutrientsPer100g.magnesiumMg * factor;
    }

    Nutrients totals = totalNutrients;

    if (_currentPet != null) {
      _clinicalWarnings = _calculator.validateTherapeuticLimits(_currentPet!, _bowlIngredients, totals);
    } else {
      _clinicalWarnings = [];
    }

    notifyListeners();
  }

  // -----------------------------------------------------------------
  // ALLERGEN & TOXICITY VERIFICATION METHODS
  // -----------------------------------------------------------------

  /// Returns false if ingredient is unsafe/toxic or contains pet allergens
  bool isIngredientSafe(Ingredient ingredient) {
    if (_currentPet == null) return true;

    if (_currentPet!.species == Species.dog && (!ingredient.safeForDogs || ingredient.isToxicToDogs)) {
      return false;
    }
    if (_currentPet!.species == Species.cat && (!ingredient.safeForCats || ingredient.isToxicToCats)) {
      return false;
    }

    final petAllergens = _currentPet!.allergens.map((a) => a.trim().toLowerCase()).toSet();
    final itemAllergens = ingredient.allergenTags.map((a) => a.trim().toLowerCase()).toSet();

    if (petAllergens.intersection(itemAllergens).isNotEmpty) {
      return false;
    }

    return true;
  }

  /// Returns warning string if unsafe or null if safe
  String? checkIngredientSafety(Ingredient item) {
    if (_currentPet == null) return null;

    if (_currentPet!.species == Species.dog && (!item.safeForDogs || item.isToxicToDogs)) {
      return "WARNING! ${item.name} is toxic or unsafe for dogs.";
    }
    if (_currentPet!.species == Species.cat && (!item.safeForCats || item.isToxicToCats)) {
      return "WARNING! ${item.name} is toxic or unsafe for cats.";
    }

    for (var tag in item.allergenTags) {
      if (_currentPet!.allergens.map((e) => e.toLowerCase()).contains(tag.toLowerCase())) {
        return "WARNING! ${_currentPet!.name} is allergic to ${item.name}.";
      }
    }

    return null;
  }

  // -----------------------------------------------------------------
  // PUBLIC GETTERS
  // -----------------------------------------------------------------

  PetProfile? get currentPet => _currentPet;
  PetProfile? get selectedPet => _currentPet;

  List<Ingredient> get allIngredients => _allIngredients;
  List<Ingredient> get searchResults => _searchResults;

  List<BowlIngredient> get bowlIngredients => _bowlIngredients;
  List<BowlIngredient> get bowl => _bowlIngredients;

  double get targetDER => _targetDER;

  double get currentRER {
    if (_currentPet == null) return 0.0;
    if (_currentPet!.healthCondition == "Needs Attention" &&
        (_currentPet!.activeDisease == DiseaseType.obesity || _currentPet!.activeDisease == DiseaseType.diabetesMellitus)) {
      double idealW = _calculator.calculateIdealWeight(_currentPet!.weightKg, _currentPet!.bodyConditionScore);
      return _calculator.calculateRER(idealW);
    }
    return _calculator.calculateRER(_currentPet!.weightKg);
  }

  double get idealWeight {
    if (_currentPet == null) return 0.0;
    return _calculator.calculateIdealWeight(_currentPet!.weightKg, _currentPet!.bodyConditionScore);
  }

  double get totalKcal => _totalKcal;
  double get totalProteinGrams => _totalProteinGrams;
  double get totalFatGrams => _totalFatGrams;
  double get totalCarbsGrams => _totalCarbsGrams;
  double get totalMoistureGrams => _totalMoistureGrams;
  double get totalCalciumMg => _totalCalciumMg;
  double get totalVitaminsMg => _totalVitaminsMg;
  double get totalMineralsMg => _totalMineralsMg;
  double get totalPhosphorusMg => _totalPhosphorusMg;
  double get totalFiberGrams => _totalFiberGrams;

  Nutrients get totalNutrients => Nutrients(
    kcal: _totalKcal,
    proteinGrams: _totalProteinGrams,
    fatGrams: _totalFatGrams,
    carbsGrams: _totalCarbsGrams,
    calciumMg: _totalCalciumMg,
    phosphorusMg: _totalPhosphorusMg,
    vitaminsGrams: _totalVitaminsMg,
    mineralsGrams: _totalMineralsMg,
    moistureGrams: _totalMoistureGrams,
    fiberGrams: _totalFiberGrams,
    sodiumMg: _totalSodiumMg,
    magnesiumMg: _totalMagnesiumMg,
  );

  int get mealsPerDay => _mealsPerDay;

  void setMealsPerDay(int meals) {
    _mealsPerDay = meals.clamp(1, 3);
    notifyListeners();
  }

  double get targetMealCalories => _mealsPerDay > 0 ? (_targetDER / _mealsPerDay) : _targetDER;

  double get adequacyRatio => targetMealCalories > 0 ? (_totalKcal / targetMealCalories) * 100.0 : 0.0;

  AdequacyCategory get adequacyStatus => _calculator.getAdequacyCategory(_totalKcal, targetMealCalories);

  bool get isSickPet => _currentPet?.healthCondition == "Needs Attention";

  DiseaseType get activeDisease => _currentPet?.activeDisease ?? DiseaseType.none;

  List<String> get clinicalWarnings => _clinicalWarnings;

  bool get hasClinicalViolation => _clinicalWarnings.isNotEmpty;

  bool get canFeedMeal => !hasClinicalViolation && _totalKcal > 0;

  bool get canSaveOrFeed => !hasClinicalViolation && adequacyRatio >= 90.0 && adequacyRatio <= 110.0;
}
