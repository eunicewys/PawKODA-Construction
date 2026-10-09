enum PetSize { small, medium, large }

/// BreedModel: Represents breed metadata loaded from offline JSON or Firestore.
class BreedModel {
  final String breedId;
  final String species;
  final String name;
  final String sizeCategory; // "Small", "Medium", "Large"
  final double avgAdultWeightKg;

  BreedModel({
    required this.breedId,
    required this.species,
    required this.name,
    required this.sizeCategory,
    required this.avgAdultWeightKg,
  });

  PetSize get sizeEnum {
    switch (sizeCategory.toLowerCase()) {
      case 'small':
        return PetSize.small;
      case 'medium':
        return PetSize.medium;
      case 'large':
        return PetSize.large;
      default:
        return PetSize.small;
    }
  }

  factory BreedModel.fromJson(Map<String, dynamic> json) {
    return BreedModel(
      breedId: (json['breedId'] ?? json['id'] ?? '').toString(),
      species: (json['species'] ?? 'Dog').toString(),
      name: (json['name'] ?? 'Unknown Breed').toString(),
      sizeCategory: (json['sizeCategory'] ?? 'Small').toString(),
      avgAdultWeightKg: (json['avgAdultWeightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory BreedModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return BreedModel.fromJson({...map, if (id != null) 'breedId': id});
  }

  Map<String, dynamic> toJson() {
    return {
      'breedId': breedId,
      'species': species,
      'name': name,
      'sizeCategory': sizeCategory,
      'avgAdultWeightKg': avgAdultWeightKg,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}

/// Backward compatibility alias for BreedInfo
typedef BreedInfo = BreedModel;
