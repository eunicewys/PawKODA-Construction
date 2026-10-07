import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_model.dart';

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

  /// Updates only the health status flag of a pet in Firestore (fast & lightweight).
  Future<void> updatePetHealthStatus(String userId, String petId, bool? isHealthy) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('PETS')
        .doc(petId)
        .update({'isHealthy': isHealthy});
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
}
