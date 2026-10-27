import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/breed_model.dart';

/// BreedService: Singleton service for loading, caching, and querying breed data,
/// as well as automatically resolving pet size categories (Small, Medium, Large).
class BreedService {
  static final BreedService _instance = BreedService._internal();
  factory BreedService() => _instance;
  BreedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BreedModel> _breeds = [];
  bool _isLoaded = false;

  /// In-memory getter for breeds list
  List<BreedModel> get breeds => _breeds;

  /// Initializes and loads assets/data/breeds.json and Firestore BREEDS into memory
  Future<void> loadBreeds({bool forceRefresh = false}) async {
    if (_isLoaded && _breeds.isNotEmpty && !forceRefresh) return;
    try {
      List<BreedModel> loadedList = [];

      // 1. Load offline base breeds
      try {
        final String jsonString = await rootBundle.loadString('assets/data/breeds.json');
        final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
        loadedList = jsonList.map((item) => BreedModel.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint("Error loading breeds.json in BreedService: $e");
      }

      // 2. Load Firestore custom breeds
      try {
        final snapshot = await _firestore.collection('BREEDS').get();
        final firebaseBreeds = snapshot.docs.map((doc) {
          final data = doc.data();
          data['breedId'] = doc.id;
          return BreedModel.fromJson(data);
        }).toList();

        for (var customBreed in firebaseBreeds) {
          int existingIdx = loadedList.indexWhere((b) => b.breedId == customBreed.breedId || b.name.toLowerCase() == customBreed.name.toLowerCase());
          if (existingIdx >= 0) {
            loadedList[existingIdx] = customBreed;
          } else {
            loadedList.add(customBreed);
          }
        }
      } catch (e) {
        debugPrint("Error fetching Firestore BREEDS in BreedService: $e");
      }

      _breeds = loadedList;
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error in loadBreeds: $e");
    }
  }

  /// Returns list of BreedModel filtered by species ("Dog" or "Cat")
  List<BreedModel> getBreedsBySpecies(String species) {
    String searchSpecies = species.toLowerCase();
    return _breeds.where((b) => b.species.toLowerCase() == searchSpecies).toList();
  }

  /// Returns BreedModel matching given breedId or name
  BreedModel? getBreedById(String breedId) {
    if (breedId.isEmpty) return null;
    try {
      return _breeds.firstWhere(
        (b) => b.breedId == breedId || b.name.toLowerCase() == breedId.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Maps adult weight in kg to standard size category ("Small", "Medium", "Large") based on species boundaries
  String mapWeightToSizeCategory(double weightKg, String species) {
    if (species.toLowerCase() == 'dog') {
      if (weightKg < 10.0) return "Small";
      if (weightKg <= 25.0) return "Medium";
      return "Large";
    } else {
      if (weightKg < 4.5) return "Small";
      if (weightKg <= 6.5) return "Medium";
      return "Large";
    }
  }

  /// Projects adult weight for puppies/kittens (< 12 months) using clinical age-based growth curves
  double projectAdultWeight(double currentWeightKg, int ageInMonths, String species) {
    if (ageInMonths >= 12) return currentWeightKg;

    double growthFactor;
    if (species.toLowerCase() == 'dog') {
      if (ageInMonths <= 3) {
        growthFactor = 0.35; // ~35% adult weight at 3 months
      } else if (ageInMonths <= 5) {
        growthFactor = 0.50; // ~50% adult weight at 4-5 months
      } else if (ageInMonths <= 8) {
        growthFactor = 0.75; // ~75% adult weight at 6-8 months
      } else {
        growthFactor = 0.90; // ~90% adult weight at 9-11 months
      }
    } else {
      if (ageInMonths <= 3) {
        growthFactor = 0.40;
      } else if (ageInMonths <= 6) {
        growthFactor = 0.65;
      } else if (ageInMonths <= 9) {
        growthFactor = 0.85;
      } else {
        growthFactor = 0.95;
      }
    }

    return currentWeightKg / growthFactor;
  }

  /// Automatic Breed-to-Size Resolution Logic (Cases 1, 2, and 3)
  String resolvePetSize({
    required String species,
    String? primaryBreedId,
    String? secondaryBreedId,
    bool isMixedBreed = false,
    bool isMultiMixed = false,
    double? currentWeightKg,
    int? ageInMonths,
  }) {
    // Case 3: Multi-Breed Mix (User selects "Multiple / More than 2")
    if (isMultiMixed || (isMixedBreed && (secondaryBreedId == null || secondaryBreedId.isEmpty || secondaryBreedId == 'multi_mix'))) {
      double weight = currentWeightKg ?? 5.0;
      int age = ageInMonths ?? 12;
      double estimatedAdultWeight = projectAdultWeight(weight, age, species);
      return mapWeightToSizeCategory(estimatedAdultWeight, species);
    }

    // Case 2: Dual-Breed Mix (User selects 2 distinct breeds)
    if (isMixedBreed && primaryBreedId != null && secondaryBreedId != null && secondaryBreedId.isNotEmpty) {
      BreedModel? breedA = getBreedById(primaryBreedId);
      BreedModel? breedB = getBreedById(secondaryBreedId);

      double weightA = breedA?.avgAdultWeightKg ?? (species.toLowerCase() == 'dog' ? 12.0 : 4.5);
      double weightB = breedB?.avgAdultWeightKg ?? (species.toLowerCase() == 'dog' ? 12.0 : 4.5);

      double estimatedWeight = (weightA + weightB) / 2.0;
      return mapWeightToSizeCategory(estimatedWeight, species);
    }

    // Case 1: Purebreed (User selects a single breed)
    if (primaryBreedId != null && primaryBreedId.isNotEmpty) {
      BreedModel? breedInfo = getBreedById(primaryBreedId);
      if (breedInfo != null) {
        return breedInfo.sizeCategory;
      }
    }

    // Fallback using current weight & growth curves
    if (currentWeightKg != null && currentWeightKg > 0) {
      double estimatedAdultWeight = projectAdultWeight(currentWeightKg, ageInMonths ?? 12, species);
      return mapWeightToSizeCategory(estimatedAdultWeight, species);
    }

    return "Small";
  }

  // -----------------------------------------------------------------
  // BACKWARD COMPATIBILITY METHODS
  // -----------------------------------------------------------------

  /// Resolves purebreed info from offline cache or Firestore
  Future<BreedInfo?> getPurebreedInfo(String breedId) async {
    await loadBreeds();
    BreedModel? b = getBreedById(breedId);
    if (b != null) return b;

    try {
      DocumentSnapshot doc = await _firestore.collection('BREEDS').doc(breedId).get();
      if (doc.exists) {
        return BreedInfo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint("Error fetching purebreed info from Firestore: $e");
    }
    return null;
  }

  /// Resolves dual-breed mix size for legacy callers
  Future<PetSize> resolveDualBreedMix(String breedIdA, String breedIdB, String species) async {
    await loadBreeds();
    String sizeStr = resolvePetSize(
      species: species,
      primaryBreedId: breedIdA,
      secondaryBreedId: breedIdB,
      isMixedBreed: true,
    );
    return _parseSizeString(sizeStr);
  }

  /// Resolves multi-breed mix size for legacy callers
  PetSize resolveMultiBreedMix(double currentWeightKg, int ageInMonths, String species) {
    String sizeStr = resolvePetSize(
      species: species,
      isMixedBreed: true,
      isMultiMixed: true,
      currentWeightKg: currentWeightKg,
      ageInMonths: ageInMonths,
    );
    return _parseSizeString(sizeStr);
  }

  PetSize _parseSizeString(String sizeStr) {
    switch (sizeStr.toLowerCase()) {
      case 'small': return PetSize.small;
      case 'medium': return PetSize.medium;
      case 'large': return PetSize.large;
      default: return PetSize.small;
    }
  }
}
