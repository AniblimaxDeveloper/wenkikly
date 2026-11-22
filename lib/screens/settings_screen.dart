import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_service.dart';

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
  // ... (State variables sama seperti sebelumnya, tidak dihapus)
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isDarkMode = true, _isBiometricEnabled = false, _isAutoTtsEnabled = false, _isHapticsEnabled = true;
  double _temperature = 0.7, _ttsRate = 0.5, _fontSize = 15.0;
  int _accentColorValue = 0xFF673AB7;
  String _selectedPersona = 'default';
  String _tier = 'free';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sub = SubscriptionService();
    setState(() {
      _tier = 'free'; // Placeholder, nanti di-load async
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _fontSize = prefs.getDouble('font_size') ?? 15.0;
      _accentColorValue = prefs.getInt('accent_color') ?? 0xFF673AB7;
    });
    final actualTier = await sub.getCurrentTier();
    setState(() => _tier = actualTier);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setDouble('font_size', _fontSize);
    await prefs.setInt('accent_color', _accentColorValue);
    widget.onThemeChanged(_isDarkMode, Color(_accentColorValue));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isPremium = _tier != 'free';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Status Langganan', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Paket: ${_tier.toUpperCase()}', style: TextStyle(color: isPremium ? Colors.green : Colors.orange)),
            trailing: const Icon(Icons.workspace_premium),
          ),
          const Divider(),
          
          SwitchListTile(title: const Text('Mode Gelap'), value: _isDarkMode, onChanged: (val) => setState(() => _isDarkMode = val)),
          SwitchListTile(title: const Text('Kunci Biometrik'), value: _isBiometricEnabled, onChanged: (val) => setState(() => _isBiometricEnabled = val)),
          
          const Divider(),
          const Text('Warna Tema', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(spacing: 12, children: [Colors.deepPurple, Colors.blue, Colors.green].map((color) => GestureDetector(onTap: () => setState(() => _accentColorValue = color.value), child: CircleAvatar(backgroundColor: color, radius: 16, child: _accentColorValue == color.value ? const Icon(Icons.check, size: 16) : null))).toList()),
          
          const Divider(),
          // FITUR TERKUNCI UNTUK FREE USER
          ListTile(
            title: const Text('Custom API Key (Bawa Sendiri)'),
            subtitle: Text(isPremium ? 'Atur API Key OpenRouter Anda' : 'Khusus Paket Plus ke atas'),
            trailing: Icon(isPremium ? Icons.key : Icons.lock, color: isPremium ? Colors.green : Colors.grey),
            enabled: isPremium,
            onTap: () { /* Buka dialog API Key */ },
          ),
          
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _saveSettings, child: const Text('SIMPAN PENGATURAN')),
        ],
      ),
    );
  }
}
