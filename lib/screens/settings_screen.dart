import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(bool) onBiometricChanged;
  const SettingsScreen({super.key, required this.onThemeChanged, required this.onBiometricChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  bool _isDarkMode = true;
  bool _isBiometricEnabled = false;
  bool _isAutoTtsEnabled = false;
  double _temperature = 0.7;
  int _accentColorValue = 0xFF673AB7;
  String _selectedPersona = 'default';

  final Map<String, String> _personas = {
    'default': '',
    'programmer': 'Kamu adalah programmer senior. Jawab dengan kode yang bersih, efisien, dan berikan penjelasan singkat.',
    'writer': 'Kamu adalah penulis kreatif profesional. Gunakan bahasa yang indah, imajinatif, dan menarik.',
    'teacher': 'Kamu adalah guru yang sabar dan pintar. Jelaskan konsep rumit dengan analogi sederhana yang mudah dipahami.',
  };

  final List<Color> _accentColors = [Colors.deepPurple, Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.teal];

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
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isAutoTtsEnabled = prefs.getBool('auto_tts_enabled') ?? false; // FITUR BARU
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
      
      final currentPrompt = _systemPromptController.text;
      _selectedPersona = _personas.entries.firstWhere((e) => e.value == currentPrompt, orElse: () => const MapEntry('custom', '')).key;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_key', _apiKeyController.text.trim());
    await prefs.setString('system_prompt', _systemPromptController.text.trim());
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await prefs.setBool('auto_tts_enabled', _isAutoTtsEnabled); // FITUR BARU
    await prefs.setDouble('temperature', _temperature);
    await prefs.setInt('accent_color', _accentColorValue);
    
    widget.onThemeChanged(_isDarkMode);
    widget.onBiometricChanged(_isBiometricEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan!')));
      Navigator.pop(context);
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wenkikly_sessions');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua riwayat chat telah dihapus.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Lanjutan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(title: const Text('Mode Gelap (Dark Mode)'), value: _isDarkMode, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isDarkMode = val)),
          SwitchListTile(title: const Text('Kunci Biometrik (Sidik Jari)'), subtitle: const Text('Minta sidik jari saat membuka aplikasi'), value: _isBiometricEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isBiometricEnabled = val)),
          SwitchListTile(title: const Text('Auto-Bacakan (Auto-TTS)'), subtitle: const Text('Bacakan jawaban AI secara otomatis'), value: _isAutoTtsEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isAutoTtsEnabled = val)),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('Warna Tema Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _accentColors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _accentColorValue = color.value),
                child: CircleAvatar(backgroundColor: color, radius: 20, child: _accentColorValue == color.value ? const Icon(Icons.check, color: Colors.white, size: 20) : null),
              );
            }).toList(),
          ),

          const Divider(height: 30, color: Colors.white24),
          const Text('Kreativitas AI (Temperature)', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: _temperature, min: 0.0, max: 1.5, divisions: 15, label: _temperature.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _temperature = val)),

          const Divider(height: 30, color: Colors.white24),
          const Text('Persona AI (System Prompt)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPersona == 'custom' ? null : _selectedPersona,
            hint: const Text('Pilih Persona...'),
            items: _personas.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key == 'default' ? 'Default (Tanpa Persona)' : e.key.toUpperCase()))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() { _selectedPersona = val; _systemPromptController.text = _personas[val] ?? ''; });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _systemPromptController, maxLines: 3, decoration: InputDecoration(hintText: 'Atau ketik instruksi kustom di sini...', filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('API Key OpenRouter', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _apiKeyController, obscureText: true, decoration: InputDecoration(hintText: 'sk-or-v1-...', filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(backgroundColor: Color(_accentColorValue), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Simpan Semua Pengaturan')),
          
          const Divider(height: 40, color: Colors.white24),
          OutlinedButton(onPressed: _clearHistory, style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: const Text('Hapus Semua Riwayat Chat')),
        ],
      ),
    );
  }
}
