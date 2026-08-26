import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';

/**
 * main: The starting point of the whole application.
 */
void main() async {
  // Ensure that Flutter is ready before we start Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the Firebase service
  // Note: If you have run 'flutterfire configure', you can use DefaultFirebaseOptions.currentPlatform
  await Firebase.initializeApp();

  // Run the app and wrap it in MultiProvider
  runApp(
    MultiProvider(
      providers: [
        // This makes UserProvider accessible to the entire app
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
      debugShowCheckedModeBanner: false, // Hides the "Debug" banner in the corner
      
      // Define the Look and Feel (Theme) of the app
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF759C86), // Soft Sage Green
        scaffoldBackgroundColor: const Color(0xFFF8F9F8), // Soft Off-White
        
        // ColorScheme: Defines colors for buttons, surfaces, and text
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF759C86),
          primary: const Color(0xFF759C86),
          secondary: const Color(0xFFD4C2AD), // Muted Sand
          surface: Colors.white,
          onSurface: const Color(0xFF2D3142), // Dark Charcoal
        ),
        
        // TextTheme: Defines default styles for all text in the app
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFF2D3142)),
          bodyMedium: TextStyle(color: Color(0xFF2D3142)),
        ),
      ),
      
      // The app starts at the Login Screen
      home: const LoginScreen(),
    );
  }
}
