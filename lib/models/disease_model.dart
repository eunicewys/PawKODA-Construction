/// DiseaseType: Represents clinical conditions supported by the PawKODA Nutrition Engine.
enum DiseaseType {
  none,
  obesity,
  ckd,
  diabetesMellitus,
  pancreatitis,
  urinaryHealth,
}

/// DiseaseProfile: Defines clinical thresholds, safety limits, and warning templates for disease-specific routing.
class DiseaseProfile {
  final DiseaseType type;
  final String displayName;
  final List<String> applicableSpecies; // ['Dog', 'Cat']
  final bool requiresIdealWeight;
  final double? dogAlphaOverride;
  final double? catAlphaOverride;
  final double? maxFatGramsPer1000KcalDog;
  final double? maxFatDmPercentDog;
  final double? maxFatDmPercentCat;
  final double? maxPhosphorusMgPer1000Kcal;
  final double? maxProteinDmPercentDog;
  final double? maxProteinDmPercentCat;
  final double? maxSodiumDmPercent;
  final double? maxCarbPercentMECat;
  final double? minFiberDmPercentDog;
  final double? minMoisturePercentCat;
  final double? minMoisturePercentDog;
  final double? maxMagnesiumDmPercentDog;
  final double? maxMagnesiumDmPercentCat;
  final String clinicalWarningTemplate;

  const DiseaseProfile({
    required this.type,
    required this.displayName,
    required this.applicableSpecies,
    this.requiresIdealWeight = false,
    this.dogAlphaOverride,
    this.catAlphaOverride,
    this.maxFatGramsPer1000KcalDog,
    this.maxFatDmPercentDog,
    this.maxFatDmPercentCat,
    this.maxPhosphorusMgPer1000Kcal,
    this.maxProteinDmPercentDog,
    this.maxProteinDmPercentCat,
    this.maxSodiumDmPercent,
    this.maxCarbPercentMECat,
    this.minFiberDmPercentDog,
    this.minMoisturePercentCat,
    this.minMoisturePercentDog,
    this.maxMagnesiumDmPercentDog,
    this.maxMagnesiumDmPercentCat,
    this.clinicalWarningTemplate = "",
  });

  /// Pre-configured lookup map containing clinical thresholds for all diseases.
  static const Map<DiseaseType, DiseaseProfile> _profiles = {
    DiseaseType.none: DiseaseProfile(
      type: DiseaseType.none,
      displayName: "Healthy Baseline",
      applicableSpecies: ['Dog', 'Cat'],
    ),
    DiseaseType.obesity: DiseaseProfile(
      type: DiseaseType.obesity,
      displayName: "Obesity / Weight Loss",
      applicableSpecies: ['Dog', 'Cat'],
      requiresIdealWeight: true,
      dogAlphaOverride: 1.0,
      catAlphaOverride: 0.8,
      maxFatDmPercentDog: 10.0,
      minFiberDmPercentDog: 8.0,
      clinicalWarningTemplate: "Weight Loss Alert: Active weight loss recipes require ≤ 10% DM fat and ≥ 8% DM fiber.",
    ),
    DiseaseType.ckd: DiseaseProfile(
      type: DiseaseType.ckd,
      displayName: "Chronic Kidney Disease (CKD)",
      applicableSpecies: ['Dog', 'Cat'],
      dogAlphaOverride: 1.1,
      catAlphaOverride: 1.1,
      maxPhosphorusMgPer1000Kcal: 800.0,
      maxProteinDmPercentDog: 20.0,
      maxProteinDmPercentCat: 35.0,
      maxSodiumDmPercent: 0.3,
      clinicalWarningTemplate: "Phosphorus Warning: CKD requires ≤ 800mg P / 1,000 kcal to protect renal nephrons.",
    ),
    DiseaseType.diabetesMellitus: DiseaseProfile(
      type: DiseaseType.diabetesMellitus,
      displayName: "Diabetes Mellitus",
      applicableSpecies: ['Dog', 'Cat'],
      requiresIdealWeight: true,
      dogAlphaOverride: 1.0,
      catAlphaOverride: 1.0,
      maxCarbPercentMECat: 15.0,
      minFiberDmPercentDog: 8.0,
      maxFatDmPercentDog: 15.0,
      clinicalWarningTemplate: "Glycemic Alert: Diabetes requires low carbs (Cats ≤ 15% ME) or high fiber & controlled fat (Dogs).",
    ),
    DiseaseType.pancreatitis: DiseaseProfile(
      type: DiseaseType.pancreatitis,
      displayName: "Pancreatitis",
      applicableSpecies: ['Dog', 'Cat'],
      dogAlphaOverride: 1.0,
      catAlphaOverride: 1.0,
      maxFatGramsPer1000KcalDog: 25.0,
      maxFatDmPercentDog: 12.0,
      maxFatDmPercentCat: 25.0,
      maxCarbPercentMECat: 20.0,
      clinicalWarningTemplate: "High Fat Alert: Pancreatitis requires strict fat restriction to avoid exocrine flare-ups.",
    ),
    DiseaseType.urinaryHealth: DiseaseProfile(
      type: DiseaseType.urinaryHealth,
      displayName: "Urinary Issue",
      applicableSpecies: ['Dog', 'Cat'],
      dogAlphaOverride: 1.1,
      catAlphaOverride: 1.1,
      minMoisturePercentDog: 70.0,
      minMoisturePercentCat: 75.0,
      maxMagnesiumDmPercentDog: 0.10,
      maxMagnesiumDmPercentCat: 0.08,
      clinicalWarningTemplate: "Hydration Warning: Urinary crystal prevention requires high moisture (Cats ≥75%, Dogs ≥70%).",
    ),
  };

  /// Returns the pre-configured clinical profile for a given disease type.
  static DiseaseProfile getProfile(DiseaseType type) {
    return _profiles[type] ?? _profiles[DiseaseType.none]!;
  }
}
