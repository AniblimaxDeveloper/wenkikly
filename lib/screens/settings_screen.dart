import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool, Color) onThemeChanged;
  final Function(bool) onBiometricChanged;
  final Function(String) onLanguageChanged;
  final Function(double) onFontSizeChanged;
  
  const SettingsScreen({
    super.key, 
    required this.onThemeChanged, 
    required this.onBiometricChanged, 
    required this.onLanguageChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _appTitleController = TextEditingController();
  
  bool _isDarkMode = true;
  bool _isBiometricEnabled = false;
  bool _isAutoTtsEnabled = false;
  bool _isHapticsEnabled = true;
  double _temperature = 0.7;
  double _ttsRate = 0.5;
  double _fontSize = 15.0;
  int _accentColorValue = 0xFF673AB7;
  String _selectedPersona = 'default';
  String _appLanguage = 'id';

  final Map<String, String> _personas = {
    'default': '',
    'programmer': 'Kamu adalah programmer senior. Jawab dengan kode yang bersih.',
    'writer': 'Kamu adalah penulis kreatif profesional.',
    'teacher': 'Kamu adalah guru yang sabar dan pintar.',
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
      _appTitleController.text = prefs.getString('app_title') ?? 'Wenkikly AI';
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isAutoTtsEnabled = prefs.getBool('auto_tts_enabled') ?? false;
      _isHapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
      _fontSize = prefs.getDouble('font_size') ?? 15.0;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
      _appLanguage = prefs.getString('app_language') ?? 'id';
      
      final currentPrompt = _systemPromptController.text;
      _selectedPersona = _personas.entries.firstWhere((e) => e.value == currentPrompt, orElse: () => const MapEntry('custom', '')).key;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_key', _apiKeyController.text.trim());
    await prefs.setString('system_prompt', _systemPromptController.text.trim());
    await prefs.setString('app_title', _appTitleController.text.trim());
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await prefs.setBool('auto_tts_enabled', _isAutoTtsEnabled);
    await prefs.setBool('haptics_enabled', _isHapticsEnabled);
    await prefs.setDouble('temperature', _temperature);
    await prefs.setDouble('tts_rate', _ttsRate);
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setInt('accent_color', _accentColorValue);
    await prefs.setString('app_language', _appLanguage);
    
    widget.onThemeChanged(_isDarkMode, Color(_accentColorValue));
    widget.onBiometricChanged(_isBiometricEnabled);
    widget.onLanguageChanged(_appLanguage);
    widget.onFontSizeChanged(_fontSize);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan!')));
      Navigator.pop(context);
    }
  }

  Future<void> _factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aplikasi di-reset. Restart aplikasi.')));
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
          const Text('Nama Aplikasi (Header)', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _appTitleController, decoration: const InputDecoration(hintText: 'Wenkikly AI')),
          const Divider(height: 30, color: Colors.white24),
          
          SwitchListTile(title: const Text('Mode Gelap'), value: _isDarkMode, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isDarkMode = val)),
          SwitchListTile(title: const Text('Kunci Biometrik'), value: _isBiometricEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isBiometricEnabled = val)),
          SwitchListTile(title: const Text('Auto-TTS'), value: _isAutoTtsEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isAutoTtsEnabled = val)),
          SwitchListTile(title: const Text('Getaran (Haptics)'), value: _isHapticsEnabled, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isHapticsEnabled = val)),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('Tampilan & Suara', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Ukuran Font Chat', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(value: _fontSize, min: 12.0, max: 20.0, divisions: 8, label: _fontSize.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _fontSize = val)),
          
          const Text('Kecepatan Suara (TTS)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(value: _ttsRate, min: 0.2, max: 1.0, divisions: 8, label: _ttsRate.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _ttsRate = val)),
          
          const Text('Kreativitas AI (Temperature)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(value: _temperature, min: 0.0, max: 1.5, divisions: 15, label: _temperature.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _temperature = val)),

          const Divider(height: 30, color: Colors.white24),
          const Text('Warna Tema', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _accentColors.map((color) => GestureDetector(
              onTap: () => setState(() => _accentColorValue = color.value),
              child: CircleAvatar(backgroundColor: color, radius: 20, child: _accentColorValue == color.value ? const Icon(Icons.check, color: Colors.white, size: 20) : null),
            )).toList(),
          ),

          const Divider(height: 30, color: Colors.white24),
          const Text('Persona AI (System Prompt)', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _selectedPersona == 'custom' ? null : _selectedPersona,
            items: _personas.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key == 'default' ? 'Default' : e.key.toUpperCase()))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() { _selectedPersona = val; _systemPromptController.text = _personas[val] ?? ''; });
              }
            },
          ),
          TextField(controller: _systemPromptController, maxLines: 3, decoration: const InputDecoration(hintText: 'Kustom prompt...')),

          const Divider(height: 30, color: Colors.white24),
          const Text('API Key OpenRouter', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _apiKeyController, obscureText: true, decoration: const InputDecoration(hintText: 'sk-or-v1-...')),
          
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(backgroundColor: Color(_accentColorValue), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('SIMPAN PENGATURAN')),
          
          const Divider(height: 40, color: Colors.white24),
          OutlinedButton(onPressed: _factoryReset, style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: const Text('FACTORY RESET (Hapus Semua Data)')),
        ],
      ),
    );
  }
}
