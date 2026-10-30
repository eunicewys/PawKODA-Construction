import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';
import '../models/disease_model.dart';

class PetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches the real-time list of pets for a specific user.
  Stream<List<PetProfile>> streamUserPets(String userId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetProfile.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Adds a new pet to the user's Firestore collection.
  Future<void> addPet(String userId, PetProfile pet) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .add(pet.toMap());
  }

  /// Deletes a pet from the user's Firestore collection.
  Future<void> deletePet(String userId, String petId) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .delete();
  }

  /// Updates an existing pet in the user's Firestore collection.
  Future<void> updatePet(String userId, String petId, PetProfile pet) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .update(pet.toMap());
  }

  /// Updates only the health status flag & active disease of a pet in Firestore (fast & lightweight).
  Future<void> updatePetHealthStatus(String userId, String petId, bool? isHealthy, {DiseaseType? activeDisease}) async {
    Map<String, dynamic> updateData = {'isHealthy': isHealthy};
    if (activeDisease != null) {
      updateData['activeDisease'] = activeDisease.name;
    } else if (isHealthy == true) {
      updateData['activeDisease'] = DiseaseType.none.name;
    }
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .update(updateData);
  }

  /// Streams a single pet's data from Firestore.
  Stream<PetProfile?> streamPet(String userId, String petId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return PetProfile.fromMap(snapshot.data()!, snapshot.id);
        });
  }

  /// Fetches a single pet by ID once.
  Future<PetProfile?> getPet(String userId, String petId) async {
    try {
      final doc = await _db
          .collection('USERS')
          .doc(userId)
          .collection('PETS')
          .doc(petId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return PetProfile.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Fetches all user pets once.
  Future<List<PetProfile>> getUserPets(String userId) async {
    try {
      final snapshot = await _db
          .collection('USERS')
          .doc(userId)
          .collection('PETS')
          .get();
      return snapshot.docs
          .map((doc) => PetProfile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Logs a fed meal to USERS/{userId}/PETS/{petId}/MEAL_LOGS
  Future<void> logFedMeal(String userId, String petId, double kcal, String mealName) async {
    if (userId.isEmpty || petId.isEmpty || kcal <= 0) return;
    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _db
          .collection('USERS')
          .doc(userId)
          .collection('PETS')
          .doc(petId)
          .collection('MEAL_LOGS')
          .add({
        'kcal': kcal,
        'mealName': mealName,
        'timestamp': Timestamp.fromDate(now),
        'dateStr': todayStr,
      });
    } catch (e) {
      debugPrint("Error logging fed meal: $e");
    }
  }

  /// Streams total calories consumed today by a specific pet (auto-resets at midnight!)
  Stream<double> streamTodayConsumedCalories(String userId, String petId) {
    if (userId.isEmpty || petId.isEmpty) {
      return Stream.value(0.0);
    }

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .collection('MEAL_LOGS')
        .where('dateStr', isEqualTo: todayStr)
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['kcal'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    });
  }
}
