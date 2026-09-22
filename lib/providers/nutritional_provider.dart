import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../models/ingredient_model.dart';
import '../services/nutrition_calculator_service.dart';

class NutritionalProvider extends ChangeNotifier {
  final NutritionCalculatorService _calculator = NutritionCalculatorService();
  
  PetProfile? _selectedPet;
  List<BowlIngredient> _bowl = [];

  PetProfile? get selectedPet => _selectedPet;
  List<BowlIngredient> get bowl => _bowl;

  void setSelectedPet(PetProfile pet) {
    _selectedPet = pet;
    _bowl = []; // Reset bowl when pet changes
    notifyListeners();
  }

  void addIngredient(Ingredient item, double massGrams) {
    if (_selectedPet == null) return;
    
    _bowl.add(BowlIngredient(ingredient: item, massGrams: massGrams));
    notifyListeners();
  }

  void removeIngredient(String ingredientId) {
    _bowl.removeWhere((item) => item.ingredient.ingredientId == ingredientId);
    notifyListeners();
  }

  void clearBowl() {
    _bowl = [];
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
