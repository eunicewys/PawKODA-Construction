enum Species { dog, cat }

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
    return PetProfile(
      id: docId,
      name: map['name'] ?? '',
      species: Species.values.firstWhere((e) => e.name == map['species'], orElse: () => Species.dog),
      weightKg: (map['weightKg'] ?? 0.0).toDouble(),
      birthDate: map['birthDate'] != null 
          ? DateTime.parse(map['birthDate']) 
          : DateTime.now(),
      condition: PetCondition.values.firstWhere((e) => e.name == map['condition'], orElse: () => PetCondition.neutered),
      activityLevel: ActivityLevel.values.firstWhere((e) => e.name == map['activityLevel'], orElse: () => ActivityLevel.moderate),
      allergens: List<String>.from(map['allergens'] ?? []),
      breed: map['breed'] ?? 'Unknown',
      imageUrl: map['imageUrl'],
      isHealthy: map['isHealthy'] ?? true,
    );
  }
}
