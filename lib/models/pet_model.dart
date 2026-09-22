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
  final String name;
  final Species species;
  final Gender gender; // New field
  final double weightKg;
  final DateTime birthDate; // Use DateTime for precise age tracking
  final PetCondition condition;
  final ActivityLevel activityLevel;
  final List<String> allergens;
  final String breed;
  final String? imageUrl;
  final bool isHealthy;

  PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.gender,
    required this.weightKg,
    required this.birthDate,
    required this.condition,
    this.activityLevel = ActivityLevel.moderate,
    required this.allergens,
    this.breed = "Unknown",
    this.imageUrl,
    this.isHealthy = true,
  });

  // Helper to calculate age in months dynamically
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species.name,
      'gender': gender.name,
      'weightKg': weightKg,
      'birthDate': birthDate.toIso8601String(),
      'condition': condition.name,
      'activityLevel': activityLevel.name,
      'allergens': allergens,
      'breed': breed,
      'imageUrl': imageUrl,
      'isHealthy': isHealthy,
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

    return PetProfile(
      id: docId,
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
      imageUrl: map['imageUrl'],
      isHealthy: map['isHealthy'] ?? true,
    );
  }
}
