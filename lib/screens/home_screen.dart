import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home/user_home_screen.dart';
import 'home/vet_home_screen.dart';
import 'home/admin_home_screen.dart';

/**
 * HomeScreen: This is the "Switchboard" screen.
 * It doesn't show any UI itself, but instead checks the user's role 
 * from UserProvider and displays the correct Dashboard (Owner, Vet, or Admin).
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the user's role from our Global Memory (Provider)
    final userProvider = context.watch<UserProvider>();
    final String role = userProvider.role ?? 'owner';

    // 2. Decide which screen to show based on the role
    if (role == 'admin') {
      return const AdminHomeScreen();
    } else if (role == 'vet') {
      return const VetHomeScreen();
    } else {
      // Default is the Pet Owner (User) Dashboard
      return const UserHomeScreen();
    }
  }
}
