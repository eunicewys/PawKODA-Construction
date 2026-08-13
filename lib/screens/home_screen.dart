import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //listens changes in UserProvider automatically
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${userProvider.userName}'),
      ),
      body: Center(
        child: Text('Current Role: ${userProvider.userRole}'),
      ),
    );
  }
}