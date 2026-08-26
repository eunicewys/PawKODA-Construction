import 'package:flutter/material.dart';

/**
 * UserProvider: This class acts like a "Global Memory" for the app.
 * It stores information about the logged-in user so that any screen
 * (like Home or Profile) can easily access the user's name and role.
 */
class UserProvider extends ChangeNotifier {
  // Private variables to store user data
  String? _uid;
  String? _displayName;
  String? _role; // Can be 'owner', 'vet', or 'admin'
  String? _email;

  // Getters: These allow other screens to READ the data but not change it directly
  String? get uid => _uid;
  String? get displayName => _displayName;
  String? get role => _role;
  String? get email => _email;

  // Check if a user is currently logged in
  bool get isLoggedIn => _uid != null;

  /**
   * setUser: Call this after a successful Login or Registration.
   * It fills the "Global Memory" with the user's details.
   */
  void setUser(String uid, String name, String role, String email) {
    _uid = uid;
    _displayName = name;
    _role = role;
    _email = email;
    
    // notifyListeners() tells the whole app: "Hey, the user data changed! Please refresh the screens."
    notifyListeners();
  }

  /**
   * clearUser: Call this when the user logs out to wipe the memory.
   */
  void clearUser() {
    _uid = null;
    _displayName = null;
    _role = null;
    _email = null;
    
    notifyListeners();
  }
}
