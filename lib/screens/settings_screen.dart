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
  bool _isFullWidth = false, _isAutoScroll = true, _hideTokens = false;
  double _temperature = 0.7, _ttsRate = 0.5, _fontSize = 15.0;
  int _accentColorValue = 0xFF673AB7;
  int _networkTimeout = 60;
  String _tier = 'free';

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
      _hideTokens = prefs.getBool('hide_tokens_global') ?? false;
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
      _fontSize = prefs.getDouble('font_size') ?? 15.0;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
      _networkTimeout = prefs.getInt('network_timeout') ?? 60;
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
    await prefs.setBool('hide_tokens_global', _hideTokens);
    await prefs.setDouble('temperature', _temperature);
    await prefs.setDouble('tts_rate', _ttsRate);
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setInt('accent_color', _accentColorValue);
    await prefs.setInt('network_timeout', _networkTimeout);
    
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
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(title: const Text('Pengaturan Lanjutan'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(title: const Text('Mode Gelap', style: TextStyle(color: Colors.white)), value: _isDarkMode, activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _isDarkMode = val)),
          SwitchListTile(title: const Text('Kunci Biometrik', style: TextStyle(color: Colors.white)), value: _isBiometricEnabled, activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _isBiometricEnabled = val)),
          SwitchListTile(title: const Text('Auto-TTS (Bacakan Jawaban)', style: TextStyle(color: Colors.white)), value: _isAutoTtsEnabled, activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _isAutoTtsEnabled = val)),
          SwitchListTile(title: const Text('Getaran (Haptics)', style: TextStyle(color: Colors.white)), value: _isHapticsEnabled, activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _isHapticsEnabled = val)),
          SwitchListTile(title: const Text('Bubble Chat Full-Width', style: TextStyle(color: Colors.white)), value: _isFullWidth, activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _isFullWidth = val)),
          SwitchListTile(title: const Text('Auto-Scroll ke Bawah', style: TextStyle(color: Colors.white)), value: _isAutoScroll, activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _isAutoScroll = val)),
          
          const Divider(color: Colors.white24, height: 30),
          const Text('Tampilan & Suara', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ukuran Font Chat', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Slider(value: _fontSize, min: 12.0, max: 20.0, divisions: 8, label: _fontSize.toStringAsFixed(1), activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _fontSize = val)),
          
          const Text('Kecepatan Suara (TTS)', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Slider(value: _ttsRate, min: 0.2, max: 1.0, divisions: 8, label: _ttsRate.toStringAsFixed(1), activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _ttsRate = val)),
          
          const Text('Kreativitas AI (Temperature)', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Slider(value: _temperature, min: 0.0, max: 1.5, divisions: 15, label: _temperature.toStringAsFixed(1), activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _temperature = val)),

          const Divider(color: Colors.white24, height: 30),
          const Text('Koneksi & API', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _apiUrlController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'API Base URL', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _apiKeyController, style: const TextStyle(color: Colors.white), obscureText: true, decoration: const InputDecoration(labelText: 'API Key OpenRouter', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text('Timeout Jaringan (detik)', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Slider(value: _networkTimeout.toDouble(), min: 10, max: 180, divisions: 17, label: '$_networkTimeout s', activeColor: Colors.deepPurpleAccent, onChanged: (val) => setState(() => _networkTimeout = val.toInt())),
          
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('SIMPAN PENGATURAN', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
