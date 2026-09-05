import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';

/**
 * main: The starting point of the app.
 */
void main() async {
  // 1. Initialize Flutter and Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Wrap the entire app in MultiProvider to share data (UserProvider)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const PawKODAApp(),
    ),
  );
}

class PawKODAApp extends StatelessWidget {
  const PawKODAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawKODA',
      debugShowCheckedModeBanner: false, // Hides the debug tag
      
      // 3. Set the "Morandi" Design Theme
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF759C86), // Sage Green
        scaffoldBackgroundColor: const Color(0xFFF8F9F8), // Soft White Background
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF759C86),
          primary: const Color(0xFF759C86),
          surface: Colors.white,
          onSurface: const Color(0xFF2D3142), // Dark Charcoal Text
        ),
        
        // Define default text styles
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFF2D3142)),
        ),
      ),
      
      // 4. Set the initial screen
      home: const LoginScreen(),
    );
  }
}
