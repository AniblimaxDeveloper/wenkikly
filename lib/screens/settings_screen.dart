import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool, Color) onThemeChanged;
  final Function(bool) onBiometricChanged;
  final Function(String) onLanguageChanged;
  final Function(double) onFontSizeChanged;
  
  const SettingsScreen({
    super.key, required this.onThemeChanged, required this.onBiometricChanged, 
    required this.onLanguageChanged, required this.onFontSizeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isDarkMode = true, _isBiometricEnabled = false, _isAutoTtsEnabled = false, _isHapticsEnabled = true;
  bool _isFullWidth = false, _isAutoScroll = true, _isAutoTranslate = false;
  double _temperature = 0.7, _ttsRate = 0.5, _fontSize = 15.0;
  int _accentColorValue = 0xFF673AB7;
  int _networkTimeout = 60;
  String _tone = 'default';

  final List<Color> _accentColors = [Colors.deepPurple, Colors.blue, Colors.pink, Colors.amber, Colors.teal];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
      _apiUrlController.text = prefs.getString('custom_api_url') ?? 'https://openrouter.ai/api/v1/chat/completions';
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isAutoTtsEnabled = prefs.getBool('auto_tts_enabled') ?? false;
      _isHapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _isFullWidth = prefs.getBool('is_full_width') ?? false;
      _isAutoScroll = prefs.getBool('is_auto_scroll') ?? true;
      _isAutoTranslate = prefs.getBool('auto_translate') ?? false;
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
      _fontSize = prefs.getDouble('font_size') ?? 15.0;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
      _networkTimeout = prefs.getInt('network_timeout') ?? 60;
      _tone = prefs.getString('ai_tone') ?? 'default';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_key', _apiKeyController.text.trim());
    await prefs.setString('custom_api_url', _apiUrlController.text.trim());
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await prefs.setBool('auto_tts_enabled', _isAutoTtsEnabled);
    await prefs.setBool('haptics_enabled', _isHapticsEnabled);
    await prefs.setBool('is_full_width', _isFullWidth);
    await prefs.setBool('is_auto_scroll', _isAutoScroll);
    await prefs.setBool('auto_translate', _isAutoTranslate);
    await prefs.setDouble('temperature', _temperature);
    await prefs.setDouble('tts_rate', _ttsRate);
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setInt('accent_color', _accentColorValue);
    await prefs.setInt('network_timeout', _networkTimeout);
    await prefs.setString('ai_tone', _tone);
    
    widget.onThemeChanged(_isDarkMode, Color(_accentColorValue));
    widget.onBiometricChanged(_isBiometricEnabled);
    widget.onFontSizeChanged(_fontSize);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pengaturan Lanjutan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0B0F), Color(0xFF1A1A2E), Color(0xFF0B0B0F)]),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
          children: [
            const Text('Warna Aksen (Liquid Glass)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: _accentColors.map((c) => GestureDetector(
              onTap: () => setState(() => _accentColorValue = c.value),
              child: CircleAvatar(backgroundColor: c, radius: 20, child: _accentColorValue == c.value ? const Icon(Icons.check, color: Colors.white) : null),
            )).toList()),
            const Divider(color: Colors.white24, height: 40),
            
            SwitchListTile(title: const Text('Mode Gelap', style: TextStyle(color: Colors.white)), value: _isDarkMode, activeColor: Color(_accentColorValue), onChanged: (v) => setState(() => _isDarkMode = v)),
            SwitchListTile(title: const Text('Kunci Biometrik', style: TextStyle(color: Colors.white)), value: _isBiometricEnabled, activeColor: Color(_accentColorValue), onChanged: (v) => setState(() => _isBiometricEnabled = v)),
            SwitchListTile(title: const Text('Auto-TTS', style: TextStyle(color: Colors.white)), value: _isAutoTtsEnabled, activeColor: Color(_accentColorValue), onChanged: (v) => setState(() => _isAutoTtsEnabled = v)),
            SwitchListTile(title: const Text('Auto-Translate (Indo/Eng)', style: TextStyle(color: Colors.white)), value: _isAutoTranslate, activeColor: Color(_accentColorValue), onChanged: (v) => setState(() => _isAutoTranslate = v)),
            SwitchListTile(title: const Text('Bubble Full-Width', style: TextStyle(color: Colors.white)), value: _isFullWidth, activeColor: Color(_accentColorValue), onChanged: (v) => setState(() => _isFullWidth = v)),
            
            const Divider(color: Colors.white24, height: 40),
            DropdownButtonFormField<String>(
              value: _tone,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Gaya Bahasa AI (Tone)', labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Default (Normal)')),
                DropdownMenuItem(value: 'professional', child: Text('Professional (Formal)')),
                DropdownMenuItem(value: 'casual', child: Text('Casual (Santai)')),
                DropdownMenuItem(value: 'funny', child: Text('Funny (Lucu)')),
              ],
              onChanged: (v) => setState(() => _tone = v!),
            ),
            const SizedBox(height: 16),
            
            const Text('Kreativitas AI (Temperature)', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Slider(value: _temperature, min: 0.0, max: 1.5, divisions: 15, label: _temperature.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (v) => setState(() => _temperature = v)),
            
            const Divider(color: Colors.white24, height: 40),
            TextField(controller: _apiUrlController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'API URL', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _apiKeyController, style: const TextStyle(color: Colors.white), obscureText: true, decoration: const InputDecoration(labelText: 'API Key', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder())),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings, 
              style: ElevatedButton.styleFrom(backgroundColor: Color(_accentColorValue), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
              child: const Text('SIMPAN PENGATURAN', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}
