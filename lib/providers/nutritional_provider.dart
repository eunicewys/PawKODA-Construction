import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../models/ingredient_model.dart';
import '../models/disease_model.dart';
import '../services/nutrition_calculator_service.dart';

/// NutritionalProvider: Manages state for pet selection, ingredient bowl composition,
/// live caloric/nutrient recalculations, and clinical safety validations.
class NutritionalProvider extends ChangeNotifier {
  final NutritionCalculatorService _calculator = NutritionCalculatorService();

  // State Properties
  PetProfile? _currentPet;
  List<BowlIngredient> _bowlIngredients = [];
  double _targetDER = 0.0;
  List<String> _clinicalWarnings = [];

  // Cumulative Nutrient Totals
  double _totalKcal = 0.0;
  double _totalProteinGrams = 0.0;
  double _totalFatGrams = 0.0;
  double _totalCarbsGrams = 0.0;
  double _totalMoistureGrams = 0.0;
  double _totalCalciumMg = 0.0;
  double _totalPhosphorusMg = 0.0;
  double _totalFiberGrams = 0.0;
  double _totalMagnesiumMg = 0.0;

  // -----------------------------------------------------------------
  // REACTIVE LIFECYCLE METHODS
  // -----------------------------------------------------------------

  /// Updates the active pet profile and recalculates target DER & bowl state
  void setPet(PetProfile pet) {
    _currentPet = pet;
    _targetDER = _calculator.calculateTargetDER(pet);
    _bowlIngredients = []; // Reset bowl when pet changes
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

  /// Recalculates all cumulative nutrient totals and validates therapeutic limits
  void recalculateNutrients() {
    Nutrients totals = _calculator.calculateBowlTotal(_bowlIngredients);

    _totalKcal = totals.kcal;
    _totalProteinGrams = totals.proteinGrams;
    _totalFatGrams = totals.fatGrams;
    _totalCarbsGrams = totals.carbsGrams;
    _totalMoistureGrams = totals.moistureGrams;
    _totalCalciumMg = totals.calciumMg;
    _totalPhosphorusMg = totals.phosphorusMg;
    _totalFiberGrams = totals.fiberGrams;
    _totalMagnesiumMg = totals.magnesiumMg;

    if (_currentPet != null) {
      _clinicalWarnings = _calculator.validateTherapeuticLimits(_currentPet!, _bowlIngredients, totals);
    } else {
      _clinicalWarnings = [];
    }

    notifyListeners();
  }

  // -----------------------------------------------------------------
  // PUBLIC GETTERS
  // -----------------------------------------------------------------

  PetProfile? get currentPet => _currentPet;
  PetProfile? get selectedPet => _currentPet;

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
  double get totalPhosphorusMg => _totalPhosphorusMg;
  double get totalFiberGrams => _totalFiberGrams;
  double get totalMagnesiumMg => _totalMagnesiumMg;

  Nutrients get totalNutrients => Nutrients(
    kcal: _totalKcal,
    proteinGrams: _totalProteinGrams,
    fatGrams: _totalFatGrams,
    carbsGrams: _totalCarbsGrams,
    calciumMg: _totalCalciumMg,
    phosphorusMg: _totalPhosphorusMg,
    vitaminsGrams: 0.0,
    mineralsGrams: 0.0,
    moistureGrams: _totalMoistureGrams,
    fiberGrams: _totalFiberGrams,
    sodiumMg: 0.0,
    magnesiumMg: _totalMagnesiumMg,
  );

  double get adequacyRatio => _targetDER > 0 ? (_totalKcal / _targetDER) * 100.0 : 0.0;

  AdequacyCategory get adequacyStatus => _calculator.getAdequacyCategory(_totalKcal, _targetDER);

  bool get isSickPet => _currentPet?.healthCondition == "Needs Attention";

  DiseaseType get activeDisease => _currentPet?.activeDisease ?? DiseaseType.none;

  List<String> get clinicalWarnings => _clinicalWarnings;

  bool get hasClinicalViolation => _clinicalWarnings.isNotEmpty;

  bool get canSaveOrFeed => !hasClinicalViolation && adequacyRatio >= 90.0 && adequacyRatio <= 110.0;

  /// Ingredient Toxicity & Allergen Interceptor
  String? checkIngredientSafety(Ingredient item) {
    if (_currentPet == null) return null;
    return _calculator.checkIngredientSafety(item, _currentPet!);
  }
}
