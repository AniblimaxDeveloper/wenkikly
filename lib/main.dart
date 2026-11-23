import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart'; // Kita pecah chat_screen biar rapi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Pastikan google-services.json ada!
  } catch (e) {
    debugPrint('Firebase error: $e');
  }
  runApp(const WenkiklyApp());
}

class WenkiklyApp extends StatefulWidget {
  const WenkiklyApp({super.key});
  @override
  State<WenkiklyApp> createState() => _WenkiklyAppState();
}

class _WenkiklyAppState extends State<WenkiklyApp> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    setState(() => _isLoggedIn = _authService.isLoggedIn());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wenkikly AI',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      ),
      // SPLASH SCREEN ANIMASI
      home: SplashScreen(
        nextScreen: _isLoggedIn 
          ? ChatScreen(onLogout: () { _authService.signOut(); _checkLogin(); })
          : AuthScreen(onLoginSuccess: _checkLogin),
      ),
    );
  }
}
