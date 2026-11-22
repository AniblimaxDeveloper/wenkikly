import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
      _systemPromptController.text = prefs.getString('system_prompt') ?? '';
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_key', _apiKeyController.text.trim());
    await prefs.setString('system_prompt', _systemPromptController.text.trim());
    await prefs.setBool('is_dark_mode', _isDarkMode);
    
    widget.onThemeChanged(_isDarkMode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan!')));
      Navigator.pop(context);
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wenkikly_sessions');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua riwayat chat dihapus.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Lanjutan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Sesuaikan tema aplikasi'),
            value: _isDarkMode,
            activeColor: Colors.deepPurple,
            onChanged: (val) => setState(() => _isDarkMode = val),
          ),
          const Divider(height: 30, color: Colors.white24),
          const Text('System Prompt (Persona AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Beri tahu AI siapa dirinya. Contoh: "Kamu adalah programmer senior yang menjawab dengan singkat."', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _systemPromptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: Kamu adalah guru matematika yang sabar...',
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text('API Key OpenRouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'sk-or-v1-...',
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Simpan Semua Pengaturan'),
          ),
          const Divider(height: 40, color: Colors.white24),
          OutlinedButton(
            onPressed: _clearHistory,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
            child: const Text('Hapus Semua Riwayat Chat'),
          ),
        ],
      ),
    );
  }
}
