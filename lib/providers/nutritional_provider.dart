import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../models/ingredient_model.dart';
import '../services/nutrition_calculator_service.dart';

class NutritionalProvider extends ChangeNotifier {
  final NutritionCalculatorService _calculator = NutritionCalculatorService();
  
  PetProfile? _selectedPet;
  double _mealMassGrams = 200.0;
  List<BowlIngredient> _bowl = [];

  PetProfile? get selectedPet => _selectedPet;
  double get mealMassGrams => _mealMassGrams;
  List<BowlIngredient> get bowl => _bowl;

  void setSelectedPet(PetProfile pet) {
    _selectedPet = pet;
    _bowl = []; // Reset bowl when pet changes
    notifyListeners();
  }

  void setMealMass(double grams) {
    _mealMassGrams = grams;
    // Update all ingredients in the bowl with the new mass
    _bowl = _bowl.map((item) => BowlIngredient(
      ingredient: item.ingredient,
      massGrams: _mealMassGrams
    )).toList();
    notifyListeners();
  }

  void addIngredient(Ingredient item) {
    if (_selectedPet == null) return;
    
    // Safety check is handled by UI calling checkIngredientSafety first
    _bowl.add(BowlIngredient(ingredient: item, massGrams: _mealMassGrams));
    notifyListeners();
  }

  void removeIngredient(String ingredientId) {
    _bowl.removeWhere((item) => item.ingredient.ingredientId == ingredientId);
    notifyListeners();
  }

  // Live Calculations
  double get targetDER => _selectedPet != null ? _calculator.calculateDER(_selectedPet!) : 0.0;
  double get currentRER => _selectedPet != null ? _calculator.calculateRER(_selectedPet!.weightKg) : 0.0;

  Nutrients get totalNutrients => _calculator.calculateBowlTotal(_bowl);
  
  double get adequacyRatio => targetDER > 0 ? (totalNutrients.kcal / targetDER) : 0.0;

  AdequacyCategory get adequacyStatus => _calculator.getAdequacyCategory(totalNutrients.kcal, targetDER);

  String? checkIngredientSafety(Ingredient item) {
    if (_selectedPet == null) return null;
    return _calculator.checkIngredientSafety(item, _selectedPet!);
  }
}
