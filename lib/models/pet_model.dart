import 'disease_model.dart';

enum Species { dog, cat }

enum Gender { male, female }

enum PetCondition {
  neutered,
  intact,
  senior,
  inactive,
  pregnant,
  nursing
}

enum ActivityLevel { low, moderate, high }

class PetProfile {
  final String id;
  final String userId;
  final String name;
  final Species species;
  final Gender gender;
  final double weightKg;
  final DateTime birthDate;
  final PetCondition condition;
  final ActivityLevel activityLevel;
  final List<String> allergens;
  final String breed;
  final bool isMixedBreed;
  final String? secondaryBreedId;
  final bool isMultiMixed;
  final String? imageUrl;
  final bool? isHealthy; // Null means not logged yet
  final String healthCondition; // "Healthy" vs "Needs Attention" (defaults to "Healthy")
  final DiseaseType activeDisease; // Defaults to DiseaseType.none
  final int bodyConditionScore; // 1 to 9 scale; defaults to 5 for ideal weight

  PetProfile({
    required this.id,
    this.userId = "",
    required this.name,
    required this.species,
    required this.gender,
    required this.weightKg,
    required this.birthDate,
    required this.condition,
    this.activityLevel = ActivityLevel.moderate,
    required this.allergens,
    this.breed = "Unknown",
    this.isMixedBreed = false,
    this.secondaryBreedId,
    this.isMultiMixed = false,
    this.imageUrl,
    this.isHealthy,
    this.healthCondition = "Healthy",
    this.activeDisease = DiseaseType.none,
    this.bodyConditionScore = 5,
  });

  /// Alias for petId
  String get petId => id;

  /// Helper to calculate age in months dynamically
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  /// Auto-resolved sizeCategory ("Small", "Medium", "Large") based on species & weight
  String get sizeCategory {
    if (species == Species.dog) {
      if (weightKg < 10.0) return "Small";
      if (weightKg <= 25.0) return "Medium";
      return "Large";
    } else {
      if (weightKg < 4.5) return "Small";
      if (weightKg <= 6.5) return "Medium";
      return "Large";
    }
  }

  /// Resolves standard lifeStageOrCondition String
  String get lifeStageOrCondition {
    if (ageInMonths < 12) return "puppy_or_kitten";
    switch (condition) {
      case PetCondition.neutered:
      case PetCondition.inactive:
        return "adult_neutered";
      case PetCondition.intact:
        return "adult_intact";
      case PetCondition.senior:
        return "senior";
      case PetCondition.pregnant:
        return "pregnant";
      case PetCondition.nursing:
        return "nursing";
    }
  }

  PetProfile copyWith({
    String? id,
    String? userId,
    String? name,
    Species? species,
    Gender? gender,
    double? weightKg,
    DateTime? birthDate,
    PetCondition? condition,
    ActivityLevel? activityLevel,
    List<String>? allergens,
    String? breed,
    bool? isMixedBreed,
    String? secondaryBreedId,
    bool? isMultiMixed,
    String? imageUrl,
    bool? isHealthy,
    String? healthCondition,
    DiseaseType? activeDisease,
    int? bodyConditionScore,
  }) {
    return PetProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      birthDate: birthDate ?? this.birthDate,
      condition: condition ?? this.condition,
      activityLevel: activityLevel ?? this.activityLevel,
      allergens: allergens ?? this.allergens,
      breed: breed ?? this.breed,
      isMixedBreed: isMixedBreed ?? this.isMixedBreed,
      secondaryBreedId: secondaryBreedId ?? this.secondaryBreedId,
      isMultiMixed: isMultiMixed ?? this.isMultiMixed,
      imageUrl: imageUrl ?? this.imageUrl,
      isHealthy: isHealthy ?? this.isHealthy,
      healthCondition: healthCondition ?? this.healthCondition,
      activeDisease: activeDisease ?? this.activeDisease,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': id,
      'userId': userId,
      'name': name,
      'species': species.name,
      'gender': gender.name,
      'weightKg': weightKg,
      'birthDate': birthDate.toIso8601String(),
      'condition': condition.name,
      'activityLevel': activityLevel.name,
      'allergens': allergens,
      'breed': breed,
      'isMixedBreed': isMixedBreed,
      'secondaryBreedId': secondaryBreedId,
      'isMultiMixed': isMultiMixed,
      'imageUrl': imageUrl,
      'isHealthy': isHealthy,
      'healthCondition': healthCondition,
      'activeDisease': activeDisease.name,
      'bodyConditionScore': bodyConditionScore,
    };
  }

  factory PetProfile.fromMap(Map<String, dynamic> map, String docId) {
    // Strict Validation Checklist
    final requiredFields = ['name', 'species', 'gender', 'weightKg', 'birthDate', 'condition'];
    for (var field in requiredFields) {
      if (map[field] == null) {
        throw FormatException("Pet profile '$docId' is missing mandatory field: $field");
      }
    }

    bool? isHealthyVal = map['isHealthy'];
    String healthCondVal = map['healthCondition'] ?? (isHealthyVal == false ? "Needs Attention" : "Healthy");

    return PetProfile(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'],
      species: Species.values.firstWhere(
        (e) => e.name == map['species'], 
        orElse: () => throw FormatException("Invalid species '${map['species']}' for pet $docId")
      ),
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'], 
        orElse: () => throw FormatException("Invalid gender '${map['gender']}' for pet $docId")
      ),
      weightKg: (map['weightKg'] as num).toDouble(),
      birthDate: DateTime.parse(map['birthDate']),
      condition: PetCondition.values.firstWhere(
        (e) => e.name == map['condition'], 
        orElse: () => throw FormatException("Invalid condition '${map['condition']}' for pet $docId")
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == (map['activityLevel'] ?? 'moderate'), 
        orElse: () => ActivityLevel.moderate
      ),
      allergens: List<String>.from(map['allergens'] ?? []),
      breed: map['breed'] ?? 'Unknown',
      isMixedBreed: map['isMixedBreed'] ?? false,
      secondaryBreedId: map['secondaryBreedId'],
      isMultiMixed: map['isMultiMixed'] ?? false,
      imageUrl: map['imageUrl'],
      isHealthy: isHealthyVal,
      healthCondition: healthCondVal,
      activeDisease: DiseaseType.values.firstWhere(
        (e) => e.name == map['activeDisease'],
        orElse: () => DiseaseType.none,
      ),
      bodyConditionScore: (map['bodyConditionScore'] as num?)?.toInt() ?? 5,
    );
  }
}

/// Typedef for PetModel alias
typedef PetModel = PetProfile;
