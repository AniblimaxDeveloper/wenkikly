import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(bool) onBiometricChanged;
  final Function(String) onLanguageChanged;
  const SettingsScreen({super.key, required this.onThemeChanged, required this.onBiometricChanged, required this.onLanguageChanged});

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
  String _appLanguage = 'id';
  String _ttsVoice = 'default';

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
      _isAutoTtsEnabled = prefs.getBool('auto_tts_enabled') ?? false;
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
      _appLanguage = prefs.getString('app_language') ?? 'id';
      _ttsVoice = prefs.getString('tts_voice') ?? 'default';
      
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
    await prefs.setBool('auto_tts_enabled', _isAutoTtsEnabled);
    await prefs.setDouble('temperature', _temperature);
    await prefs.setInt('accent_color', _accentColorValue);
    await prefs.setString('app_language', _appLanguage);
    await prefs.setString('tts_voice', _ttsVoice);
    
    widget.onThemeChanged(_isDarkMode);
    widget.onBiometricChanged(_isBiometricEnabled);
    widget.onLanguageChanged(_appLanguage);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Lanjutan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // BAHASA APLIKASI
          const Text('Bahasa Aplikasi / App Language', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: RadioListTile<String>(title: const Text('Indonesia'), value: 'id', groupValue: _appLanguage, onChanged: (v) => setState(() => _appLanguage = v!))),
              Expanded(child: RadioListTile<String>(title: const Text('English'), value: 'en', groupValue: _appLanguage, onChanged: (v) => setState(() => _appLanguage = v!))),
            ],
          ),
          const Divider(height: 30, color: Colors.white24),

          SwitchListTile(title: const Text('Mode Gelap (Dark Mode)'), value: _isDarkMode, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isDarkMode = val)),
          SwitchListTile(title: const Text('Kunci Biometrik (Sidik Jari)'), value: _isBiometricEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isBiometricEnabled = val)),
          SwitchListTile(title: const Text('Auto-Bacakan (Auto-TTS)'), value: _isAutoTtsEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isAutoTtsEnabled = val)),
          
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
          const Text('Pilihan Suara TTS', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _ttsVoice,
            items: const [
              DropdownMenuItem(value: 'default', child: Text('Default System')),
              DropdownMenuItem(value: 'male', child: Text('Pria (Male)')),
              DropdownMenuItem(value: 'female', child: Text('Wanita (Female)')),
            ],
            onChanged: (val) => setState(() => _ttsVoice = val!),
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
          TextField(controller: _systemPromptController, maxLines: 3, decoration: InputDecoration(hintText: 'Atau ketik instruksi kustom...', filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('API Key OpenRouter', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _apiKeyController, obscureText: true, decoration: InputDecoration(hintText: 'sk-or-v1-...', filled: true, fillColor: const Color(0xFF2C2C2C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(backgroundColor: Color(_accentColorValue), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Simpan Semua Pengaturan')),
        ],
      ),
    );
  }
}
