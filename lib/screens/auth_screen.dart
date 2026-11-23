import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLogin = false;
  bool _isLoading = false;
  bool _agreeTerms = false;

  void _submitEmail() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap setujui Syarat & Ketentuan!')));
      return;
    }
    setState(() => _isLoading = true);
    String? error = _isLogin 
      ? await _authService.signInWithEmail(_emailController.text, _passwordController.text)
      : await _authService.registerWithEmail(_emailController.text, _passwordController.text);
    
    setState(() => _isLoading = false);
    if (error == null) {
      widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _submitGoogle() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap setujui Syarat & Ketentuan!')));
      return;
    }
    setState(() => _isLoading = true);
    String? error = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);
    if (error == null) {
      widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _dummySocialLogin(String provider) async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap setujui Syarat & Ketentuan!')));
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    await _authService.signInWithEmail('$provider@wenkikly.com', '123');
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurpleAccent),
                    const SizedBox(height: 16),
                    Text('Wenkikly AI', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Ultra Intelligent Assistant', style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _emailController, 
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email', 
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true, fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      ), 
                      keyboardType: TextInputType.emailAddress
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController, 
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password', 
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true, fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      ), 
                      obscureText: true
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Checkbox(value: _agreeTerms, activeColor: Colors.deepPurpleAccent, onChanged: (v) => setState(() => _agreeTerms = v!)),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse('https://wenkikly.com/terms')),
                            child: const Text('Saya menyetujui Syarat & Ketentuan Wenkikly.', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'MASUK' : 'DAFTAR', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk', style: const TextStyle(color: Colors.white54))),
                    
                    const Divider(height: 40, color: Colors.white24),
                    const Text('Atau masuk dengan:', style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
                      children: [
                        _oauthButton('Google', Icons.g_mobiledata, Colors.red, _submitGoogle),
                        _oauthButton('Apple', Icons.apple, Colors.white, () => _dummySocialLogin('Apple')),
                        _oauthButton('X', Icons.close, Colors.white, () => _dummySocialLogin('X')),
                        _oauthButton('Facebook', Icons.facebook, Colors.blue, () => _dummySocialLogin('Facebook')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _oauthButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2))),
        child: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white))]),
      ),
    );
  }
}
