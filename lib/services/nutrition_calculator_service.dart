import 'dart:math';
import '../models/pet_model.dart';
import '../models/ingredient_model.dart';

enum AdequacyCategory { insufficient, lacking, optimal, excess }

class NutritionCalculatorService {
  
  /// Calculates Resting Energy Requirement (RER)
  /// RER = 70 * (weightKg ^ 0.75)
  double calculateRER(double weightKg) {
    return (70 * pow(weightKg, 0.75)).toDouble();
  }

  /// Resolves the Dynamic Multiplier (alpha) based on Species, Age, and Condition
  double getAlpha(PetProfile pet) {
    if (pet.species == Species.dog) {
      return _getDogAlpha(pet);
    } else {
      return _getCatAlpha(pet);
    }
  }

  double _getDogAlpha(PetProfile pet) {
    if (pet.ageInMonths < 4) return 3.0; // Puppy
    if (pet.ageInMonths < 12) return 2.0; // Growing Puppy
    
    switch (pet.condition) {
      case PetCondition.neutered: return 1.6;
      case PetCondition.intact: return 1.8;
      case PetCondition.senior: return 1.2;
      case PetCondition.inactive: return 1.0;
      case PetCondition.pregnant: return 2.2;
      case PetCondition.nursing: return 4.0;
    }
  }

  double _getCatAlpha(PetProfile pet) {
    if (pet.ageInMonths < 4) return 2.5; // Kitten
    if (pet.ageInMonths < 12) return 2.0; // Growing Kitten
    
    switch (pet.condition) {
      case PetCondition.neutered: return 1.2;
      case PetCondition.intact: return 1.4;
      case PetCondition.senior: return 1.1;
      case PetCondition.inactive: return 0.8;
      case PetCondition.pregnant: return 1.8;
      case PetCondition.nursing: return 3.5;
    }
  }

  /// Calculates Daily Energy Requirement (DER)
  /// DER = RER * alpha
  double calculateDER(PetProfile pet) {
    double rer = calculateRER(pet.weightKg);
    double alpha = getAlpha(pet);
    return rer * alpha;
  }

  /// Aggregates total nutrients across all selected bowl ingredients
  Nutrients calculateBowlTotal(List<BowlIngredient> bowl) {
    double totalKcal = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;
    double totalCalcium = 0;
    double totalPhosphorus = 0;
    double totalVitamins = 0;
    double totalMinerals = 0;
    double totalMoisture = 0;

    for (var item in bowl) {
      var n = item.scaledNutrients;
      totalKcal += n.kcal;
      totalProtein += n.proteinGrams;
      totalFat += n.fatGrams;
      totalCarbs += n.carbsGrams;
      totalCalcium += n.calciumMg;
      totalPhosphorus += n.phosphorusMg;
      totalVitamins += n.vitaminsGrams;
      totalMinerals += n.mineralsGrams;
      totalMoisture += n.moistureGrams;
    }

    return Nutrients(
      kcal: totalKcal,
      proteinGrams: totalProtein,
      fatGrams: totalFat,
      carbsGrams: totalCarbs,
      calciumMg: totalCalcium,
      phosphorusMg: totalPhosphorus,
      vitaminsGrams: totalVitamins,
      mineralsGrams: totalMinerals,
      moistureGrams: totalMoisture,
    );
  }

  /// Computes Adequacy Ratio and returns Category
  AdequacyCategory getAdequacyCategory(double totalKcal, double calculatedDER) {
    double ratio = (totalKcal / calculatedDER) * 100;
    
    if (ratio < 70.0) return AdequacyCategory.insufficient;
    if (ratio < 90.0) return AdequacyCategory.lacking;
    if (ratio <= 110.0) return AdequacyCategory.optimal;
    return AdequacyCategory.excess;
  }

  /// Safety Check
  /// Returns null if safe, otherwise returns a warning message
  String? checkIngredientSafety(Ingredient item, PetProfile pet) {
    // 1. Toxicity check
    if (pet.species == Species.dog && item.isToxicToDogs) {
      return "WARNING! This food is toxic to ${pet.name}";
    }
    if (pet.species == Species.cat && item.isToxicToCats) {
      return "WARNING! This food is toxic to ${pet.name}";
    }

    // 2. Allergen check
    for (var tag in item.allergenTags) {
      if (pet.allergens.map((e) => e.toLowerCase()).contains(tag.toLowerCase())) {
        return "WARNING! ${pet.name} is allergic to this food";
      }
    }

    return null; // Safe
  }
}
