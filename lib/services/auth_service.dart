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

  bool isLoggedIn() {
    bool status = false;
    SharedPreferences.getInstance().then((prefs) {
      status = prefs.getBool('is_logged_in') ?? false;
    });
    return status;
  }
  
  String? getUserEmail() => 'user@wenkikly.com';
  String? getUserName() => 'Wenkikly User';
}
