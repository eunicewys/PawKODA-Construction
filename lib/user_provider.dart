import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  //private variables that hold current app state
  String _userRole = 'owner'; //default role: 'owner', 'vet', 'admin'
  String _userName = '';

  //create getters to allow UI screens to read the data safely
  String get userRole => _userRole;
  String get userName => _userName;

  //methods to update the state and notify the UI
  void setUserDetails(String name, String role) {
    _userName = name;
    _userRole = role;

    //This function tells Flutter: "Data updated! Redraw screens listening to me."
    notifyListeners();
  }
}