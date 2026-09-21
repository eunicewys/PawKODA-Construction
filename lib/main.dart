import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/nutritional_provider.dart';
import 'screens/login_screen.dart';

/// main: The starting point of the app.
void main() async {
  // 1. Initialize Flutter and Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Wrap the entire app in MultiProvider to share data
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NutritionalProvider()),
      ],
      child: const PawKODAApp(),
    ),
  );
}

class PawKODAApp extends StatelessWidget {
  const PawKODAApp({super.key});

  // Official Morandi Natural Palette
  static const Color dustyOlive = Color(0xFF6B705C);
  static const Color drySage = Color(0xFFA5A58D);
  static const Color lightBronze = Color(0xFFCB997E);
  static const Color desertSand = Color(0xFFDDBEA9);
  static const Color powderPetal = Color(0xFFFFE8D6);
  static const Color ashGrey = Color(0xFFB7B7A4);
  
  // Standard UI Colors
  static const Color darkCharcoal = Color(0xFF2D3142);
  static const Color softBlack = Color(0xFF1A1C22);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawKODA',
      debugShowCheckedModeBanner: false, // Hides the debug tag
      
      // 3. Set the official "Morandi" Design Theme
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: dustyOlive,
        scaffoldBackgroundColor: powderPetal, // Soft nature-inspired background
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: dustyOlive,
          primary: dustyOlive,
          secondary: lightBronze,
          surface: Colors.white,
          onSurface: softBlack,
        ),
        
        // Define default text styles using dark grey/black as requested
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: softBlack, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: softBlack, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: softBlack),
          bodyMedium: TextStyle(color: darkCharcoal),
          bodySmall: TextStyle(color: ashGrey),
        ),
        
        // Consistent button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: dustyOlive,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
      
      // 4. Set the initial screen
      home: const LoginScreen(),
    );
  }
}
