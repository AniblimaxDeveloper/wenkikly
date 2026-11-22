// import 'package:firebase_auth/firebase_auth.dart'; // DINONAKTIFKAN SEMENTARA
// import 'package:google_sign_in/google_sign_in.dart'; // DINONAKTIFKAN SEMENTARA
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> signInWithEmail(String email, String password) async {
    // Simulasi login sukses tanpa Firebase
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
    // Cek status login dari SharedPreferences
    bool status = false;
    SharedPreferences.getInstance().then((prefs) {
      status = prefs.getBool('is_logged_in') ?? false;
    });
    return status;
  }
  
  String? getUserEmail() => 'user@wenkikly.com';
  String? getUserName() => 'Wenkikly User';
}
