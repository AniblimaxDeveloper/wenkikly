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
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _appTitleController = TextEditingController();
  
  bool _isDarkMode = true;
  bool _isBiometricEnabled = false;
  bool _isAutoTtsEnabled = false;
  bool _isHapticsEnabled = true;
  bool _hideTokensGlobal = false;
  bool _isFullWidth = false;
  bool _isAutoScroll = true;
  
  double _temperature = 0.7;
  double _ttsRate = 0.5;
  double _fontSize = 15.0;
  int _accentColorValue = 0xFF673AB7;
  int _userBubbleColorValue = 0xFF673AB7;
  int _aiBubbleColorValue = 0xFF2C2C2C;
  int _networkTimeout = 60;
  String _selectedPersona = 'default';
  String _appLanguage = 'id';
  String _sttLanguage = 'id';
  String _timeFormat = '24h';

  final Map<String, String> _personas = {
    'default': '',
    'programmer': 'Kamu adalah programmer senior. Jawab dengan kode yang bersih.',
    'writer': 'Kamu adalah penulis kreatif profesional.',
  };

  final List<Color> _accentColors = [Colors.deepPurple, Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.teal];
  final List<Color> _bubbleColors = [Colors.deepPurple, Colors.blue, Colors.green, Colors.grey, Colors.brown, Colors.black];

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
      _systemPromptController.text = prefs.getString('system_prompt') ?? '';
      _appTitleController.text = prefs.getString('app_title') ?? 'Wenkikly AI';
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isAutoTtsEnabled = prefs.getBool('auto_tts_enabled') ?? false;
      _isHapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _hideTokensGlobal = prefs.getBool('hide_tokens_global') ?? false;
      _isFullWidth = prefs.getBool('is_full_width') ?? false;
      _isAutoScroll = prefs.getBool('is_auto_scroll') ?? true;
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
      _fontSize = prefs.getDouble('font_size') ?? 15.0;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
      _userBubbleColorValue = prefs.getInt('user_bubble_color') ?? 0xFF673AB7;
      _aiBubbleColorValue = prefs.getInt('ai_bubble_color') ?? 0xFF2C2C2C;
      _networkTimeout = prefs.getInt('network_timeout') ?? 60;
      _appLanguage = prefs.getString('app_language') ?? 'id';
      _sttLanguage = prefs.getString('stt_language') ?? 'id';
      _timeFormat = prefs.getString('time_format') ?? '24h';
      
      final currentPrompt = _systemPromptController.text;
      _selectedPersona = _personas.entries.firstWhere((e) => e.value == currentPrompt, orElse: () => const MapEntry('custom', '')).key;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_key', _apiKeyController.text.trim());
    await prefs.setString('custom_api_url', _apiUrlController.text.trim());
    await prefs.setString('system_prompt', _systemPromptController.text.trim());
    await prefs.setString('app_title', _appTitleController.text.trim());
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await prefs.setBool('auto_tts_enabled', _isAutoTtsEnabled);
    await prefs.setBool('haptics_enabled', _isHapticsEnabled);
    await prefs.setBool('hide_tokens_global', _hideTokensGlobal);
    await prefs.setBool('is_full_width', _isFullWidth);
    await prefs.setBool('is_auto_scroll', _isAutoScroll);
    await prefs.setDouble('temperature', _temperature);
    await prefs.setDouble('tts_rate', _ttsRate);
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setInt('accent_color', _accentColorValue);
    await prefs.setInt('user_bubble_color', _userBubbleColorValue);
    await prefs.setInt('ai_bubble_color', _aiBubbleColorValue);
    await prefs.setInt('network_timeout', _networkTimeout);
    await prefs.setString('app_language', _appLanguage);
    await prefs.setString('stt_language', _sttLanguage);
    await prefs.setString('time_format', _timeFormat);
    
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
          SwitchListTile(title: const Text('Sembunyikan Token Global'), value: _hideTokensGlobal, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _hideTokensGlobal = val)),
          SwitchListTile(title: const Text('Bubble Chat Full-Width'), value: _isFullWidth, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isFullWidth = val)),
          SwitchListTile(title: const Text('Auto-Scroll ke Bawah'), value: _isAutoScroll, activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _isAutoScroll = val)),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('Tampilan & Waktu', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _timeFormat,
            decoration: const InputDecoration(labelText: 'Format Jam'),
            items: const [DropdownMenuItem(value: '24h', child: Text('24 Jam (14:30)')), DropdownMenuItem(value: '12h', child: Text('12 Jam (02:30 PM)'))],
            onChanged: (val) => setState(() => _timeFormat = val!),
          ),
          const Text('Ukuran Font Chat', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(value: _fontSize, min: 12.0, max: 20.0, divisions: 8, label: _fontSize.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _fontSize = val)),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('Warna Tema Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, children: _accentColors.map((color) => GestureDetector(onTap: () => setState(() => _accentColorValue = color.value), child: CircleAvatar(backgroundColor: color, radius: 20, child: _accentColorValue == color.value ? const Icon(Icons.check, color: Colors.white, size: 20) : null))).toList()),
          
          const SizedBox(height: 16),
          const Text('Warna Bubble User & AI', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('User: '), ..._bubbleColors.map((color) => GestureDetector(onTap: () => setState(() => _userBubbleColorValue = color.value), child: Container(margin: const EdgeInsets.only(right: 8), width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: _userBubbleColorValue == color.value ? Border.all(color: Colors.white, width: 2) : null)))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('AI: '), ..._bubbleColors.map((color) => GestureDetector(onTap: () => setState(() => _aiBubbleColorValue = color.value), child: Container(margin: const EdgeInsets.only(right: 8), width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: _aiBubbleColorValue == color.value ? Border.all(color: Colors.white, width: 2) : null)))),
            ],
          ),

          const Divider(height: 30, color: Colors.white24),
          const Text('Suara & Bahasa', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _sttLanguage,
            decoration: const InputDecoration(labelText: 'Bahasa Mikrofon (STT)'),
            items: const [DropdownMenuItem(value: 'id', child: Text('Indonesia')), DropdownMenuItem(value: 'en', child: Text('English'))],
            onChanged: (val) => setState(() => _sttLanguage = val!),
          ),
          const Text('Kecepatan Suara (TTS)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(value: _ttsRate, min: 0.2, max: 1.0, divisions: 8, label: _ttsRate.toStringAsFixed(1), activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _ttsRate = val)),

          const Divider(height: 30, color: Colors.white24),
          const Text('Koneksi & API', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _apiUrlController, decoration: const InputDecoration(labelText: 'API Base URL (Ollama/OpenRouter)', hintText: 'https://openrouter.ai/api/v1/chat/completions')),
          const Text('Timeout Jaringan (detik)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(value: _networkTimeout.toDouble(), min: 10, max: 180, divisions: 17, label: '$_networkTimeout s', activeColor: Color(_accentColorValue), onChanged: (val) => setState(() => _networkTimeout = val.toInt())),
          TextField(controller: _apiKeyController, obscureText: true, decoration: const InputDecoration(labelText: 'API Key (OpenRouter)')),
          
          const Divider(height: 30, color: Colors.white24),
          const Text('Persona Default (System Prompt)', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(value: _selectedPersona == 'custom' ? null : _selectedPersona, items: _personas.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key == 'default' ? 'Default' : e.key.toUpperCase()))).toList(), onChanged: (val) { if (val != null) { setState(() { _selectedPersona = val; _systemPromptController.text = _personas[val] ?? ''; }); } }),
          TextField(controller: _systemPromptController, maxLines: 3, decoration: const InputDecoration(hintText: 'Kustom prompt...')),

          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveSettings, style: ElevatedButton.styleFrom(backgroundColor: Color(_accentColorValue), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('SIMPAN PENGATURAN')),
          
          const Divider(height: 40, color: Colors.white24),
          OutlinedButton(onPressed: _factoryReset, style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: const Text('FACTORY RESET (Hapus Semua Data)')),
        ],
      ),
    );
  }
}
