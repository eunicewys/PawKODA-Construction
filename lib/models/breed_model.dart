enum PetSize { small, medium, large }

class BreedInfo {
  final String breedId;
  final String name;
  final double avgAdultWeightKg;
  final PetSize sizeCategory;

  BreedInfo({
    required this.breedId,
    required this.name,
    required this.avgAdultWeightKg,
    required this.sizeCategory,
  });

  factory BreedInfo.fromMap(Map<String, dynamic> map, String id) {
    return BreedInfo(
      breedId: id,
      name: map['name'] ?? 'Unknown Breed',
      avgAdultWeightKg: (map['avgAdultWeightKg'] ?? 0.0).toDouble(),
      sizeCategory: _parseSize(map['sizeCategory']),
    );
  }

  static PetSize _parseSize(String? size) {
    switch (size?.toLowerCase()) {
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
}
