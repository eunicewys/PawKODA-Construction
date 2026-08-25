import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _uid;
  String? _displayName;
  String? _role; // 'owner', 'vet', 'admin'
  String? _email;

  String? get uid => _uid;
  String? get displayName => _displayName;
  String? get role => _role;
  String? get email => _email;

  bool get isLoggedIn => _uid != null;

  void setUser(String uid, String name, String role, String email) {
    _uid = uid;
    _displayName = name;
    _role = role;
    _email = email;
    notifyListeners();
  }

  void clearUser() {
    _uid = null;
    _displayName = null;
    _role = null;
    _email = null;
    notifyListeners();
  }
}
