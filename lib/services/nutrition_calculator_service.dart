import 'dart:math';
import '../models/pet_model.dart';
import '../models/ingredient_model.dart';
import '../models/disease_model.dart';

/// AdequacyCategory: Represents the caloric status relative to target DER.
enum AdequacyCategory { insufficient, lacking, optimal, excess }

/// NutritionCalculatorService: Handles RER/DER calculation, dynamic clinical routing,
/// dry matter conversions, and therapeutic safety validation.
class NutritionCalculatorService {

  // -----------------------------------------------------------------
  // 1. BASE ENERGY FORMULAS
  // -----------------------------------------------------------------

  /// Calculates Resting Energy Requirement (RER)
  /// RER = 70.0 * (weightKg ^ 0.75)
  double calculateRER(double weightKg) {
    if (weightKg <= 0) return 0.0;
    return (70.0 * pow(weightKg, 0.75)).toDouble();
  }

  /// Calculates Ideal Target Weight for Obesity / Weight Loss via 9-point BCS
  /// If BCS <= 5: return current weight
  /// If BCS > 5: currentWeightKg / (1.0 + ((bcs - 5) * 0.10))
  double calculateIdealWeight(double currentWeightKg, int bcs) {
    if (currentWeightKg <= 0) return 0.0;
    int clampedBcs = bcs.clamp(1, 9);
    if (clampedBcs <= 5) return currentWeightKg;

    double factor = 1.0 + ((clampedBcs - 5) * 0.10);
    if (factor <= 0) return currentWeightKg;
    return currentWeightKg / factor;
  }

  // -----------------------------------------------------------------
  // 2. DYNAMIC TARGET DER MULTIPLIERS (BRANCHING LOGIC)
  // -----------------------------------------------------------------

  /// Resolves healthy life-stage multiplier alpha
  double getHealthyAlpha(PetProfile pet) {
    bool isDog = pet.species == Species.dog;
    if (pet.ageInMonths < 4) return isDog ? 3.0 : 2.5; // Young Puppy / Kitten
    if (pet.ageInMonths < 12) {
      // Growing (4-12 months): Large Breed Dog = 2.2, Small/Medium Dog = 2.0, Cat = 2.0
      if (isDog && pet.sizeCategory.toLowerCase() == "large") {
        return 2.2;
      }
      return 2.0;
    }

    switch (pet.condition) {
      case PetCondition.neutered: return isDog ? 1.6 : 1.2;
      case PetCondition.intact: return isDog ? 1.8 : 1.4;
      case PetCondition.senior: return isDog ? 1.2 : 1.1;
      case PetCondition.inactive: return isDog ? 1.0 : 0.8;
      case PetCondition.pregnant: return isDog ? 2.2 : 1.8;
      case PetCondition.nursing: return isDog ? 4.0 : 3.5;
    }
  }

  /// Calculates Dynamic Target Daily Energy Requirement (DER)
  double calculateTargetDER(PetProfile pet) {
    if (pet.weightKg <= 0) return 0.0;

    // -----------------------------------------------------------------
    // BRANCH A: SICK PET ("Needs Attention" & Disease Active)
    // -----------------------------------------------------------------
    if (pet.healthCondition == "Needs Attention" && pet.activeDisease != DiseaseType.none) {
      switch (pet.activeDisease) {
        case DiseaseType.obesity:
          double idealWeight = calculateIdealWeight(pet.weightKg, pet.bodyConditionScore);
          double idealRER = calculateRER(idealWeight);
          // Dog alpha = 1.0; Cat alpha = 0.8 (prevents feline hepatic lipidosis)
          double alpha = pet.species == Species.cat ? 0.8 : 1.0;
          return idealRER * alpha;

        case DiseaseType.ckd:
          // Alpha = 1.1 * RER(currentWeight) to prevent muscle cachexia
          return calculateRER(pet.weightKg) * 1.1;

        case DiseaseType.diabetesMellitus:
          // Caloric intake anchored to ideal weight for glycemic control
          double idealWeight = calculateIdealWeight(pet.weightKg, pet.bodyConditionScore);
          double idealRER = calculateRER(idealWeight);
          return idealRER * 1.0;

        case DiseaseType.pancreatitis:
          // Maintenance baseline alpha = 1.0
          return calculateRER(pet.weightKg) * 1.0;

        case DiseaseType.urinaryHealth:
          // Maintenance baseline alpha = 1.1
          return calculateRER(pet.weightKg) * 1.1;

        default:
          break;
      }
    }

    // -----------------------------------------------------------------
    // BRANCH B: HEALTHY PET (Standard Life-Stage Alpha Multiplier)
    // -----------------------------------------------------------------
    double rer = calculateRER(pet.weightKg);
    double alpha = getHealthyAlpha(pet);
    return rer * alpha;
  }

  // -----------------------------------------------------------------
  // 3. DRY MATTER & METABOLIZABLE ENERGY CONVERSIONS
  // -----------------------------------------------------------------

  /// Converts As-Fed nutrient concentration to Dry Matter (DM) %
  double toDryMatter(double asFed, double moisturePercent) {
    double dryMatterPercent = 100.0 - moisturePercent;
    if (dryMatterPercent <= 0) return 0.0;
    return (asFed / dryMatterPercent) * 100.0;
  }

  /// Calculates Carbohydrate % Metabolizable Energy (% ME)
  double calculateCarbPercentME(double totalCarbGrams, double totalKcal) {
    if (totalKcal <= 0) return 0.0;
    return ((totalCarbGrams * 3.5) / totalKcal) * 100.0;
  }

  // -----------------------------------------------------------------
  // 4. THERAPEUTIC SAFETY VALIDATOR
  // -----------------------------------------------------------------

  /// Evaluates cumulative bowl nutrients against therapeutic safety limits.
  List<String> validateTherapeuticLimits(PetProfile pet, List<BowlIngredient> bowl, Nutrients totalNutrients) {
    // Return empty list if pet is healthy or no disease active or bowl is empty
    if (pet.healthCondition != "Needs Attention" || pet.activeDisease == DiseaseType.none || bowl.isEmpty) {
      return [];
    }

    List<String> warnings = [];
    double totalKcal = totalNutrients.kcal;
    double totalMassGrams = bowl.fold(0.0, (sum, item) => sum + item.massGrams);

    // Defensive zero-division checks
    if (totalMassGrams <= 0 || totalKcal <= 0) return [];

    double totalMoistureGrams = totalNutrients.moistureGrams;
    double moisturePercent = (totalMoistureGrams / totalMassGrams) * 100.0;
    double totalDryMassGrams = totalMassGrams - totalMoistureGrams;

    if (totalDryMassGrams <= 0) return [];

    // Dry Matter Conversions
    double fatDmPercent = (totalNutrients.fatGrams / totalDryMassGrams) * 100.0;
    double proteinDmPercent = (totalNutrients.proteinGrams / totalDryMassGrams) * 100.0;
    double fiberDmPercent = (totalNutrients.fiberGrams / totalDryMassGrams) * 100.0;
    double sodiumDmPercent = ((totalNutrients.sodiumMg / 1000.0) / totalDryMassGrams) * 100.0;
    double magnesiumDmPercent = ((totalNutrients.magnesiumMg / 1000.0) / totalDryMassGrams) * 100.0;

    // Density Conversions
    double fatDensityGramsPer1000Kcal = (totalNutrients.fatGrams / totalKcal) * 1000.0;
    double phosphorusMgPer1000Kcal = (totalNutrients.phosphorusMg / totalKcal) * 1000.0;

    // Energy Conversions
    double carbPercentME = calculateCarbPercentME(totalNutrients.carbsGrams, totalKcal);

    bool isDog = pet.species == Species.dog;
    bool isCat = pet.species == Species.cat;

    switch (pet.activeDisease) {
      case DiseaseType.pancreatitis:
        if (isDog) {
          if (fatDensityGramsPer1000Kcal > 25.0 || fatDmPercent > 12.0) {
            warnings.add("High Fat Alert: Recipe has ${fatDensityGramsPer1000Kcal.toStringAsFixed(1)}g fat/1,000 kcal. Canine pancreatitis requires ≤ 25g/1,000 kcal to prevent exocrine enzyme flare-ups.");
          }
        } else if (isCat) {
          if (fatDmPercent > 25.0 || carbPercentME > 20.0) {
            warnings.add("Pancreatitis Alert: Feline pancreatitis requires moderate fat (≤ 25% DM) and low carbohydrates (≤ 20% ME) to avoid digestive irritation.");
          }
        }
        break;

      case DiseaseType.ckd:
        if (phosphorusMgPer1000Kcal > 800.0) {
          warnings.add("Phosphorus Warning: CKD requires ≤ 800mg P / 1,000 kcal to protect renal nephrons.");
        }
        if (isDog && proteinDmPercent > 20.0) {
          warnings.add("Protein Limit: CKD dogs require ≤ 20% DM protein.");
        } else if (isCat && proteinDmPercent > 35.0) {
          warnings.add("Protein Limit: CKD cats require ≤ 35% DM protein.");
        }
        if (sodiumDmPercent > 0.3) {
          warnings.add("Sodium Warning: CKD requires ≤ 0.3% DM sodium to manage hypertension.");
        }
        break;

      case DiseaseType.diabetesMellitus:
        if (isCat) {
          if (carbPercentME > 15.0) {
            warnings.add("Carb Spike: Diabetic cats require ≤ 15% ME carbs.");
          }
        } else if (isDog) {
          if (fiberDmPercent < 8.0 || fatDmPercent > 15.0) {
            warnings.add("Glycemic Alert: Diabetic dogs require high fiber (≥ 8% DM) and controlled fat (≤ 15% DM).");
          }
        }
        break;

      case DiseaseType.urinaryHealth:
        if (isCat) {
          if (moisturePercent < 75.0 || magnesiumDmPercent > 0.08) {
            warnings.add("FLUTD Alert: Feline urinary health requires ≥ 75% moisture and ≤ 0.08% DM magnesium to dissolve struvite crystals.");
          }
        } else if (isDog) {
          if (moisturePercent < 70.0 || magnesiumDmPercent > 0.10) {
            warnings.add("Canine Urolithiasis Alert: Canine stone prevention requires ≥ 70% moisture and ≤ 0.10% DM magnesium.");
          }
        }
        break;

      case DiseaseType.obesity:
        if (fatDmPercent > 10.0) {
          warnings.add("Fat Density Alert: Active weight loss recipes require ≤ 10% DM fat.");
        }
        if (fiberDmPercent < 8.0) {
          warnings.add("Low Satiety Alert: Increase fiber (≥ 8% DM) to keep the pet full during caloric restriction.");
        }
        break;

      default:
        break;
    }

    return warnings;
  }

  // -----------------------------------------------------------------
  // 5. BOWL AGGREGATION & ADEQUACY HELPERS
  // -----------------------------------------------------------------

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
    double totalFiber = 0;
    double totalSodium = 0;
    double totalMagnesium = 0;

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
      totalFiber += n.fiberGrams;
      totalSodium += n.sodiumMg;
      totalMagnesium += n.magnesiumMg;
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
      fiberGrams: totalFiber,
      sodiumMg: totalSodium,
      magnesiumMg: totalMagnesium,
    );
  }

  /// Computes Adequacy Ratio and returns Category
  AdequacyCategory getAdequacyCategory(double totalKcal, double calculatedDER) {
    if (calculatedDER <= 0) return AdequacyCategory.insufficient;
    double ratio = (totalKcal / calculatedDER) * 100.0;
    
    if (ratio < 70.0) return AdequacyCategory.insufficient;
    if (ratio < 90.0) return AdequacyCategory.lacking;
    if (ratio <= 110.0) return AdequacyCategory.optimal;
    return AdequacyCategory.excess;
  }

  /// Toxicity & Allergen Interceptor
  String? checkIngredientSafety(Ingredient item, PetProfile pet) {
    if (pet.species == Species.dog && item.isToxicToDogs) {
      return "WARNING! This food is toxic to ${pet.name}";
    }
    if (pet.species == Species.cat && item.isToxicToCats) {
      return "WARNING! This food is toxic to ${pet.name}";
    }

    for (var tag in item.allergenTags) {
      if (pet.allergens.map((e) => e.toLowerCase()).contains(tag.toLowerCase())) {
        return "WARNING! ${pet.name} is allergic to this food";
      }
    }

    return null;
  }
}
