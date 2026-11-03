import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/nutritional_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

import 'services/breed_service.dart';
import 'services/notification_service.dart';

/// main: The starting point of the app.
void main() async {
  // 1. Initialize Flutter, Firebase, NotificationService, and BreedService
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence explicitly
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService().init();
  await BreedService().loadBreeds();

  // 2. Wrap the entire app in MultiProvider to share data
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NutritionalProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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
      
      // 4. Set the initial screen with AuthWrapper
      home: const AuthWrapper(),
    );
  }
}

/// AuthWrapper: Restores existing session (including offline session for Pet Owners)
/// or presents LoginScreen when unauthenticated.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAutoLoggedIn = false;
  String? _offlineRoleMessage;

  @override
  void initState() {
    super.initState();
    _checkCurrentUserSession();
  }

  Future<void> _checkCurrentUserSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot? userDoc;
      try {
        userDoc = await FirebaseFirestore.instance
            .collection('USERS')
            .doc(user.uid)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Fallback to local Firestore cache if offline or server timeout occurs
        userDoc = await FirebaseFirestore.instance
            .collection('USERS')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));
      }

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'owner';
        final String name = data['displayName'] ?? 'User';
        final String? photoUrl = data['photoUrl'];
        final String email = data['email'] ?? user.email ?? '';

        if (!mounted) return;
        final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
        final isOffline = connectivity.isOffline;

        // Offline access is ONLY for Pet Owners
        if (isOffline && role != 'owner') {
          _offlineRoleMessage = "Offline access is only supported for Pet Owners viewing their Pet Passports. Admin and Vet dashboards require an active internet connection.";
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isAutoLoggedIn = false;
            });
          }
          return;
        }

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(
            user.uid,
            name,
            role,
            email,
            photoUrl: photoUrl,
          );
          setState(() {
            _isAutoLoggedIn = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error checking auth session: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF6B705C),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_isAutoLoggedIn) {
      return const HomeScreen();
    }

    if (_offlineRoleMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_offlineRoleMessage!),
              backgroundColor: const Color(0xFFB56576),
              duration: const Duration(seconds: 5),
            ),
          );
          _offlineRoleMessage = null;
        }
      });
    }

    return const LoginScreen();
  }
}
