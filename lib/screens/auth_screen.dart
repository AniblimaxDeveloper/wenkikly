import 'package:flutter/material.dart';
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
  bool _isLogin = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('new_logo.png', width: 100, errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome, size: 100, color: Colors.deepPurple)),
              const SizedBox(height: 20),
              const Text('Wenkikly AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
              const Text('Ultra Intelligent Assistant', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Checkbox(value: _agreeTerms, onChanged: (v) => setState(() => _agreeTerms = v!)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse('https://wenkikly.com/terms')),
                      child: const Text('Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi Wenkikly.', style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitEmail,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'MASUK' : 'DAFTAR'),
                ),
              ),
              TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk')),
              
              const Divider(height: 40),
              const Text('Atau masuk dengan:'),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _oauthButton('Google', Icons.g_mobiledata, Colors.red, _submitGoogle),
                  _oauthButton('Apple', Icons.apple, Colors.white, () {}), // Butuh setup Apple Dev
                  _oauthButton('X', Icons.close, Colors.black, () {}), // Butuh setup X Dev
                  _oauthButton('Facebook', Icons.facebook, Colors.blue, () {}), // Butuh setup Meta Dev
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _oauthButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(label)]),
      ),
    );
  }
}
