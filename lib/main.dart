import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'screens/auth_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/about_screen.dart';
// IMPORT SEMUA FILE LAINNYA DARI SEBELUMNYA
import 'models/ai_model.dart';
import 'models/chat_session.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'dart:io';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Mungkin error jika google-services.json tidak ada
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const WenkiklyApp());
}

class WenkiklyApp extends StatefulWidget {
  const WenkiklyApp({super.key});
  @override
  State<WenkiklyApp> createState() => _WenkiklyAppState();
}

class _WenkiklyAppState extends State<WenkiklyApp> {
  bool _isLoggedIn = false;
  bool _isDarkMode = true;
  Color _accentColor = Colors.deepPurple;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    setState(() => _isLoggedIn = _authService.isLoggedIn());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wenkikly AI',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: _accentColor)),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: _accentColor, brightness: Brightness.dark)),
      
      // ROUTING: Jika belum login, lempar ke AuthScreen
      home: _isLoggedIn 
        ? ChatScreenWrapper(onLogout: () { _authService.signOut(); _checkLogin(); })
        : AuthScreen(onLoginSuccess: _checkLogin),
    );
  }
}

// Wrapper untuk menangani UI Utama setelah login
class ChatScreenWrapper extends StatelessWidget {
  final VoidCallback onLogout;
  const ChatScreenWrapper({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    // Di sini panggil ChatScreen yang asli, passing state login
    return _MainChatView(onLogout: onLogout); 
  }
}

// Ini class ChatScreen lu sebelumnya, gue ringkes di sini biar kodenya nggak kepanjangan.
// Anggap ini isi main.dart lu yang sebelumnya (dengan tombol2 tambahan).
class _MainChatView extends StatefulWidget {
  final VoidCallback onLogout;
  const _MainChatView({required this.onLogout});
  @override
  State<_MainChatView> createState() => _MainChatViewState();
}

class _MainChatViewState extends State<_MainChatView> {
  final SubscriptionService _subService = SubscriptionService();
  String _tier = 'free';

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  void _loadTier() async {
    String t = await _subService.getCurrentTier();
    setState(() => _tier = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wenkikly Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.workspace_premium), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(onPaymentSuccess: () { Navigator.pop(context); _loadTier(); })));
          }),
          IconButton(icon: const Icon(Icons.info), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: Center(
        child: Text('Selamat Datang di Wenkikly AI!\nStatus Paket: ${_tier.toUpperCase()}\n\nSemua fitur chat ada di sini (kode lama tetap utuh).'),
      ),
      // CATATAN: Di aplikasi asli, lu tinggal gabungin kode UI ChatScreen yang lama di sini.
    );
  }
}
