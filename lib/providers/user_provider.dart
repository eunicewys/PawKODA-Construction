import 'package:flutter/material.dart';

/// UserProvider: This is the "Global Memory" of the app.
/// It stores the user's information after they login or register
/// so that all other screens can access it.
class UserProvider extends ChangeNotifier {
  String? _uid;
  String? _displayName;
  String? _role; // Default is 'owner'
  String? _email;

  // Getters to safely read data from other screens
  String? get uid => _uid;
  String? get displayName => _displayName;
  String? get role => _role;
  String? get email => _email;

  // Function to save user data into memory
  void setUser(String uid, String name, String role, String email) {
    _uid = uid;
    _displayName = name;
    _role = role;
    _email = email;
    
    // This tells the app to refresh screens that are using this data
    notifyListeners();
  }

  // Function to clear memory (use this for Logout)
  void clearUser() {
    _uid = null;
    _displayName = null;
    _role = null;
    _email = null;
    notifyListeners();
  }
}
