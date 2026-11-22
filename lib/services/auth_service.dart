import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<String?> signInWithEmail(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    return null; 
  }

  Future<String?> registerWithEmail(String email, String password) async {
    return signInWithEmail(email, password);
  }

  Future<String?> signInWithGoogle() async {
    return signInWithEmail('google@wenkikly.com', '123');
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
  }

  // FIX: Ubah menjadi Future<bool> agar bisa di-await
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
  
  String? getUserEmail() => 'user@wenkikly.com';
  String? getUserName() => 'Wenkikly User';
}
