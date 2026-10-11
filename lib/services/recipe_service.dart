import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream all saved recipes for a user ordered by newest
  Stream<List<SavedRecipe>> streamUserRecipes(String userId) {
    return _db
        .collection('USERS')
        .doc(userId)
        .collection('RECIPES')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedRecipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Save a new recipe to Firestore
  Future<void> saveRecipe(String userId, SavedRecipe recipe) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('RECIPES')
        .add(recipe.toMap());
  }

  /// Delete a saved recipe from Firestore
  Future<void> deleteRecipe(String userId, String recipeId) async {
    await _db
        .collection('USERS')
        .doc(userId)
        .collection('RECIPES')
        .doc(recipeId)
        .delete();
  }
}
