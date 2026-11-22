import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 16),
            const Text('Wenkikly AI Pro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Version 3.0.0 "Titanium"', style: TextStyle(color: Colors.grey)),
            const Divider(height: 40),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Founder & Developer'),
              subtitle: Text('αριєρρ gαηтєηg', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
            ),
            const ListTile(
              leading: Icon(Icons.security),
              title: Text('Keamanan'),
              subtitle: Text('Data Anda terenkripsi dan tersimpan secara lokal.'),
            ),
            const ListTile(
              leading: Icon(Icons.warning),
              title: Text('Disclaimer'),
              subtitle: Text('AI dapat membuat kesalahan. Harap verifikasi informasi penting.'),
            ),
            const Spacer(),
            const Text('© 2026 Wenkikly. All Rights Reserved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
