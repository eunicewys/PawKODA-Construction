import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/breed_model.dart';

class BreedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Resolves the size category for a Single Purebreed pet.
  /// Fetches data from the 'BREEDS' collection in Firestore.
  Future<BreedInfo?> getPurebreedInfo(String breedId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('BREEDS').doc(breedId).get();
      if (doc.exists) {
        return BreedInfo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error fetching purebreed info: $e");
    }
    return null;
  }

  /// Resolves the size category for a Dual-Breed Mix.
  /// Averages the adult weights of two breeds and maps them to species thresholds.
  Future<PetSize> resolveDualBreedMix(String breedIdA, String breedIdB, String species) async {
    double avgA = 0.0;
    double avgB = 0.0;

    BreedInfo? infoA = await getPurebreedInfo(breedIdA);
    BreedInfo? infoB = await getPurebreedInfo(breedIdB);

    if (infoA != null) avgA = infoA.avgAdultWeightKg;
    if (infoB != null) avgB = infoB.avgAdultWeightKg;

    double estimatedWeight = (avgA + avgB) / 2.0;
    return _mapWeightToSize(estimatedWeight, species);
  }

  /// Resolves the size category for a Multi-Breed Mix (> 2 breeds).
  /// Directly uses the user-entered current weight and species thresholds.
  PetSize resolveMultiBreedMix(double currentWeightKg, int ageInMonths, String species) {
    // Note: We use thresholds directly as per instructions
    return _mapWeightToSize(currentWeightKg, species);
  }

  /// Helper to map weight to PetSize based on species thresholds.
  PetSize _mapWeightToSize(double weight, String species) {
    if (species.toLowerCase() == 'dog') {
      if (weight < 10.0) return PetSize.small;
      if (weight <= 25.0) return PetSize.medium;
      return PetSize.large;
    } else if (species.toLowerCase() == 'cat') {
      if (weight < 4.5) return PetSize.small;
      if (weight <= 6.5) return PetSize.medium;
      return PetSize.large;
    }
    // Default fallback
    return PetSize.small;
  }
}
