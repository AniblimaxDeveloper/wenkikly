import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'dart:io';
import 'dart:convert';
import 'models/ai_model.dart';
import 'models/chat_session.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'screens/settings_screen.dart';

void main() => runApp(const WenkiklyApp());

class WenkiklyApp extends StatefulWidget {
  const WenkiklyApp({super.key});
  @override
  State<WenkiklyApp> createState() => _WenkiklyAppState();
}

class _WenkiklyAppState extends State<WenkiklyApp> with WidgetsBindingObserver {
  bool _isDarkMode = true;
  bool _isBiometricEnabled = false;
  bool _isAuthenticated = false;
  String _appLanguage = 'id';
  String _appTitle = 'Wenkikly AI';
  double _fontSize = 15.0;
  Color _accentColor = Colors.deepPurple;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isBiometricEnabled) {
        setState(() => _isAuthenticated = false); 
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _accentColor = Color(prefs.getInt('accent_color') ?? 0xFF673AB7);
      _appLanguage = prefs.getString('app_language') ?? 'id';
      _appTitle = prefs.getString('app_title') ?? 'Wenkikly AI';
      _fontSize = prefs.getDouble('font_size') ?? 15.0;
    });
    if (_isBiometricEnabled) { _authenticate(); } else { setState(() => _isAuthenticated = true); }
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Pindai sidik jari untuk membuka $_appTitle',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      setState(() => _isAuthenticated = authenticated);
    } catch (e) { setState(() => _isAuthenticated = false); }
  }

  void _changeTheme(bool isDark, Color color) => setState(() { _isDarkMode = isDark; _accentColor = color; });
  void _changeBiometric(bool enabled) => setState(() => _isBiometricEnabled = enabled);
  void _changeLanguage(String lang) => setState(() => _appLanguage = lang);
  void _changeFontSize(double size) => setState(() => _fontSize = size);

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false, theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 80, color: _accentColor),
                const SizedBox(height: 20),
                Text('$_appTitle Terkunci', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _authenticate, style: ElevatedButton.styleFrom(backgroundColor: _accentColor), child: const Text('Buka dengan Sidik Jari')),
              ],
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      title: _appTitle, debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: _accentColor), appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0)),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true, textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme), colorScheme: ColorScheme.fromSeed(seedColor: _accentColor, brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF0F0F0F), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A), foregroundColor: Colors.white, elevation: 0)),
      home: ChatScreen(
        appTitle: _appTitle, fontSize: _fontSize,
        onThemeChanged: _changeTheme, onBiometricChanged: _changeBiometric, 
        onLanguageChanged: _changeLanguage, onFontSizeChanged: _changeFontSize, language: _appLanguage,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String appTitle;
  final double fontSize;
  final Function(bool, Color) onThemeChanged;
  final Function(bool) onBiometricChanged;
  final Function(String) onLanguageChanged;
  final Function(double) onFontSizeChanged;
  final String language;

  const ChatScreen({
    super.key, required this.appTitle, required this.fontSize,
    required this.onThemeChanged, required this.onBiometricChanged, 
    required this.onLanguageChanged, required this.onFontSizeChanged, required this.language
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isZenMode = false;
  bool _isAutoTts = false;
  bool _isHaptics = true;
  bool _isEnhancing = false;
  bool _hideTokens = false;
  bool _isFullWidth = false;
  bool _isAutoScroll = true;
  String _timeFormat = '24h';
  String _quotedMessage = '';

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  AIModel _selectedModel = wenkiklyModels[0];
  bool _showScrollToTop = false;
  String _searchQuery = '';
  String _chatSearchQuery = '';
  XFile? _pickedImage;
  String _selectedRatio = '1:1';

  final List<String> _quickPrompts = ["Buatkan kode Flutter UI login.", "Jelaskan AI dengan sederhana.", "Tulis artikel teknologi.", "Buat puisi senja."];
  final List<String> _randomIdeas = ["Jelaskan teori kuantum untuk anak SD.", "Buat script Python untuk scraping web.", "Tulis email lamaran kerja UI/UX.", "Berikan 5 ide bisnis modal kecil.", "Analisis SWOT aplikasi TikTok."];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadSettings();
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showScrollToTop) setState(() => _showScrollToTop = true);
      if (_scrollController.offset <= 200 && _showScrollToTop) setState(() => _showScrollToTop = false);
    });
  }

  void _initTts() async => await _flutterTts.setLanguage(widget.language == 'id' ? "id-ID" : "en-US");

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _storageService.loadSessions();
    setState(() {
      _isAutoTts = prefs.getBool('auto_tts_enabled') ?? false;
      _isHaptics = prefs.getBool('haptics_enabled') ?? true;
      _hideTokens = prefs.getBool('hide_tokens_global') ?? false;
      _isFullWidth = prefs.getBool('is_full_width') ?? false;
      _isAutoScroll = prefs.getBool('is_auto_scroll') ?? true;
      _timeFormat = prefs.getString('time_format') ?? '24h';
      _sessions = sessions;
      if (_sessions.isNotEmpty) {
        _currentSession = _sessions.first;
        _selectedModel = wenkiklyModels.firstWhere((m) => m.id == _currentSession!.modelId, orElse: () => wenkiklyModels[0]);
        _controller.text = prefs.getString('draft_${_currentSession!.id}') ?? '';
      } else {
        _createNewSession();
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      final prefs = await SharedPreferences.getInstance();
      String lang = prefs.getString('stt_language') == 'en' ? "en_US" : "id_ID";
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(localeId: lang, onResult: (val) => setState(() => _controller.text = val.recognizedWords));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await _flutterTts.setSpeechRate(prefs.getDouble('tts_rate') ?? 0.5);
    String cleanText = text.replaceAll(RegExp(r'[*#`_]'), '').replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), ''); 
    await _flutterTts.speak(cleanText);
  }

  void _stopTts() async => await _flutterTts.stop();

  void _haptic() { if (_isHaptics) HapticFeedback.lightImpact(); }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) setState(() => _pickedImage = image);
  }

  void _createNewSession() {
    final newSession = ChatSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Obrolan Baru', messages: [], modelId: _selectedModel.id);
    setState(() { _sessions.insert(0, newSession); _currentSession = newSession; _controller.clear(); _quotedMessage = ''; });
    _storageService.saveSessions(_sessions);
  }

  void _clearCurrentChat() {
    if (_currentSession != null) {
      setState(() { _currentSession!.messages.clear(); });
      _storageService.saveSessions(_sessions);
    }
  }

  void _deleteSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
      if (_currentSession?.id == id) {
        if (_sessions.isNotEmpty) {
          _currentSession = _sessions.first;
          _selectedModel = wenkiklyModels.firstWhere((m) => m.id == _currentSession!.modelId, orElse: () => wenkiklyModels[0]);
        } else _createNewSession();
      }
    });
    _storageService.saveSessions(_sessions);
  }

  void _scrollToTop() => _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  Future<void> _saveDraft(String text) async {
    if (_currentSession == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_${_currentSession!.id}', text);
  }

  Future<void> _enhanceCurrentPrompt() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isEnhancing = true);
    final enhanced = await _aiService.enhancePrompt(text);
    if (mounted) {
      setState(() { _controller.text = enhanced; _isEnhancing = false; });
      _saveDraft(enhanced);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt disempurnakan!')));
    }
  }

  void _showChatStats() {
    if (_currentSession == null) return;
    int totalMsgs = _currentSession!.messages.length;
    int totalWords = 0;
    int totalTokens = 0;
    for (var msg in _currentSession!.messages) {
      totalWords += msg['content'].toString().split(' ').length;
      totalTokens += (msg['content'].toString().length / 4).ceil();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistik Obrolan'),
        content: Text('Total Pesan: $totalMsgs\nTotal Kata: $totalWords\nEstimasi Token: ~$totalTokens'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _backupChats() async {
    if (_sessions.isEmpty) return;
    String jsonStr = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup disalin ke Clipboard!')));
  }

  void _restoreChats() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data.text!);
        setState(() {
          _sessions = decoded.map((e) => ChatSession.fromJson(e)).toList();
          if (_sessions.isNotEmpty) _currentSession = _sessions.first;
        });
        _storageService.saveSessions(_sessions);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore berhasil!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format backup tidak valid.')));
      }
    }
  }

  Future<void> _sendMessage({String? text}) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty && _pickedImage == null || _currentSession == null) return;
    if (!_selectedModel.isUnlimited && _currentSession!.messages.length >= 10) { _showLimitDialog(); return; }

    _haptic();
    String finalText = messageText.startsWith('/image ') ? '$messageText --ratio $_selectedRatio' : messageText;
    if (_quotedMessage.isNotEmpty) {
      finalText = "> $quotedMessage\n\n$finalText";
      _quotedMessage = '';
    }

    String displayContent = finalText;
    dynamic apiContent = finalText;

    if (_pickedImage != null) {
      final bytes = await _pickedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      displayContent = finalText.isEmpty ? "[Gambar Terlampir]" : finalText;
      apiContent = [
        {"type": "text", "text": finalText.isEmpty ? "Jelaskan gambar ini." : finalText},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
      ];
    }

    setState(() {
      if (_currentSession!.messages.isEmpty) _currentSession!.title = displayContent.length > 25 ? '${displayContent.substring(0, 25)}...' : displayContent;
      _currentSession!.messages.add({'role': 'user', 'content': displayContent, 'timestamp': DateTime.now().toIso8601String(), 'raw_api_content': apiContent});
      _isLoading = true;
      _pickedImage = null;
    });
    _controller.clear();
    _saveDraft('');
    _storageService.saveSessions(_sessions);
    if (_isAutoScroll) _scrollToBottom();

    final apiMessages = _currentSession!.messages.map((m) => {'role': m['role'], 'content': m['raw_api_content'] ?? m['content']}).toList();
    final reply = await _aiService.sendMessage(apiMessages, _currentSession!);

    setState(() {
      _currentSession!.messages.add({'role': 'assistant', 'content': reply, 'timestamp': DateTime.now().toIso8601String()});
      _isLoading = false;
    });
    _storageService.saveSessions(_sessions);
    if (_isAutoScroll) _scrollToBottom();

    if (_isAutoTts && !reply.startsWith('Error')) _speak(reply);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _summarizeChat() {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;
    String chatHistory = _currentSession!.messages.map((m) => "${m['role']}: ${m['content']}").join('\n');
    _sendMessage(text: "Tolong rangkum percakapan berikut menjadi poin-poin penting:\n\n$chatHistory");
  }

  void _showLimitDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Limit Tercapai'), content: const Text('Batas pesan paket Free habis. Ganti ke Unlimited.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))]));
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context, backgroundColor: Theme.of(context).scaffoldBackgroundColor, isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.7, maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Pilih Model Wenkikly', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                controller: scrollController, itemCount: wenkiklyModels.length,
                itemBuilder: (context, index) {
                  final model = wenkiklyModels[index];
                  final isSelected = model.id == _selectedModel.id;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[800], child: Icon(model.icon, color: Colors.white, size: 20)),
                    title: Row(children: [Text(model.name, style: TextStyle(color: isSelected ? Colors.deepPurpleAccent : null, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: model.isUnlimited ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(model.isUnlimited ? 'UNLIMITED' : 'LIMIT', style: TextStyle(fontSize: 10, color: model.isUnlimited ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)))]),
                    subtitle: Text(model.description, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
                    onTap: () { setState(() { _selectedModel = model; _currentSession!.modelId = model.id; }); _storageService.saveSessions(_sessions); Navigator.pop(context); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int totalTokens = 0;
    if (_currentSession != null) { for (var msg in _currentSession!.messages) { totalTokens += ((msg['content']?.toString().length ?? 0) / 4).ceil(); } }
    
    // Cek Warna Bubble
    Color userBubbleColor = const Color(0xFF673AB7);
    Color aiBubbleColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!;

    return Scaffold(
      appBar: _isZenMode ? null : AppBar(
        title: GestureDetector(
          onLongPress: _showModelSelector,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.appTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              Text('${_selectedModel.name} • ~$totalTokens tk', style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), tooltip: 'Cari di Chat', onPressed: () => showSearch(context: context, delegate: _ChatSearchDelegate(_currentSession!.messages))),
          IconButton(icon: const Icon(Icons.summarize), tooltip: 'Rangkum Chat', onPressed: _summarizeChat),
          IconButton(icon: const Icon(Icons.add_comment_outlined), tooltip: 'Chat Baru', onPressed: _createNewSession),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'export') _exportChat();
              if (val == 'stats') _showChatStats();
              if (val == 'backup') _backupChats();
              if (val == 'restore') _restoreChats();
              if (val == 'clear') _clearCurrentChat();
              if (val == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged, onBiometricChanged: widget.onBiometricChanged, onLanguageChanged: widget.onLanguageChanged, onFontSizeChanged: widget.onFontSizeChanged))).then((_) => _loadSettings());
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Ekspor Chat (MD)')),
              const PopupMenuItem(value: 'stats', child: Text('Statistik Chat')),
              const PopupMenuItem(value: 'backup', child: Text('Backup ke Clipboard')),
              const PopupMenuItem(value: 'restore', child: Text('Restore dari Clipboard')),
              const PopupMenuItem(value: 'clear', child: Text('Hapus Isi Chat Ini')),
              const PopupMenuItem(value: 'settings', child: Text('Pengaturan')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF0F0F0F) : Colors.grey[200]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Riwayat Obrolan', style: Theme.of(context).textTheme.titleLarge),
                  Text('Total Token: ~$totalTokens', style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController, onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                    decoration: InputDecoration(hintText: 'Cari obrolan...', prefixIcon: const Icon(Icons.search, size: 18), filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _sessions.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList().isEmpty 
                ? const Center(child: Text('Tidak ada obrolan', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, size: 20),
                        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        selected: session.id == _currentSession?.id,
                        selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () => _deleteSession(session.id)),
                        onTap: () { setState(() { _currentSession = session; _selectedModel = wenkiklyModels.firstWhere((m) => m.id == session.modelId, orElse: () => wenkiklyModels[0]); }); Navigator.pop(context); },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      body: _currentSession == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onDoubleTap: () => setState(() => _isZenMode = !_isZenMode),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: _currentSession!.messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    Text('Mulai percakapan dengan ${_selectedModel.name}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                                    const SizedBox(height: 24),
                                    Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: _quickPrompts.map((prompt) => ActionChip(label: Text(prompt, style: const TextStyle(fontSize: 12)), onPressed: () => _sendMessage(text: prompt), backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200], side: BorderSide.none)).toList()),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _currentSession!.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _currentSession!.messages[index];
                                  final isUser = msg['role'] == 'user';
                                  final isLastMessage = index == _currentSession!.messages.length - 1;
                                  
                                  DateTime dt = DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String());
                                  final timeStr = _timeFormat == '12h' ? DateFormat('hh:mm a').format(dt) : DateFormat('HH:mm').format(dt);
                                  final wordCount = msg['content'].toString().split(' ').length;
                                  final isImageUrl = msg['content'] != null && msg['content']!.contains('image.pollinations.ai');
                                  
                                  return Align(
                                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                    child: GestureDetector(
                                      onLongPress: () => setState(() => _quotedMessage = msg['content']),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(12),
                                        constraints: BoxConstraints(maxWidth: _isFullWidth ? MediaQuery.of(context).size.width * 0.95 : MediaQuery.of(context).size.width * 0.85),
                                        decoration: BoxDecoration(
                                          color: isUser ? Colors.deepPurple.shade700 : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                                          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isUser ? const Radius.circular(16) : Radius.zero, bottomRight: isUser ? Radius.zero : const Radius.circular(16)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isImageUrl)
                                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(msg['content']!.split('(')[1].split(')')[0], fit: BoxFit.cover))
                                            else if (isUser) 
                                              SelectableText(msg['content']!, style: TextStyle(fontSize: widget.fontSize, color: isDark ? Colors.white : Colors.black87))
                                            else
                                              MarkdownBody(
                                                  data: msg['content']!,
                                                  styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: widget.fontSize, color: isDark ? Colors.white : Colors.black87)),
                                                  builders: {'code': HighlightCodeBuilder(onExplain: (code) => _sendMessage(text: "Jelaskan kode berikut secara detail:\n\n$code"))},
                                                ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('$timeStr • $wordCount kata', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                                                  onSelected: (val) {
                                                    if (val == 'copy') { Clipboard.setData(ClipboardData(text: msg['content']!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disalin'))); }
                                                    if (val == 'share') { Share.share(msg['content']!); }
                                                    if (val == 'speak') { _speak(msg['content']!); }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(value: 'copy', child: Text('Copy')),
                                                    const PopupMenuItem(value: 'share', child: Text('Share')),
                                                    if (!isUser) const PopupMenuItem(value: 'speak', child: Text('Bacakan (TTS)')),
                                                  ],
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_isLoading)
                        Padding(padding: const EdgeInsets.all(8.0), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent)), const SizedBox(width: 12), const Text('Wenkikly sedang mengetik...', style: TextStyle(color: Colors.grey, fontSize: 12))])),
                      
                      if (!_isZenMode)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
                          child: SafeArea(
                            child: Column(
                              children: [
                                if (_quotedMessage.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[300], border: const Border(left: BorderSide(color: Colors.deepPurple, width: 4))),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(_quotedMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                                        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _quotedMessage = '')),
                                      ],
                                    ),
                                  ),
                                if (_pickedImage != null)
                                  Stack(
                                    children: [
                                      Container(height: 80, width: 80, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover))),
                                      Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => _pickedImage = null), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    CircleAvatar(backgroundColor: (isDark ? const Color(0xFF2C2C2C) : Colors.grey[300]), child: IconButton(icon: Icon(Icons.add_photo_alternate, color: (isDark ? Colors.white54 : Colors.black54), size: 20), onPressed: _pickImage)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _controller, onChanged: _saveDraft, style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                        maxLength: 4000,
                                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text('$currentLength/$maxLength', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                                        decoration: InputDecoration(
                                          hintText: 'Tanya ${_selectedModel.name}...',
                                          filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          suffixIcon: _isEnhancing ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(icon: const Icon(Icons.auto_fix_high, color: Colors.amberAccent), onPressed: _enhanceCurrentPrompt),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(backgroundColor: Colors.deepPurple, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _isLoading ? null : () => _sendMessage())),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_showScrollToTop)
                    Positioned(bottom: 80, right: 16, child: FloatingActionButton.small(backgroundColor: Colors.deepPurple, onPressed: _scrollToTop, child: const Icon(Icons.arrow_upward, color: Colors.white))),
                  Positioned(bottom: 80, left: 16, child: FloatingActionButton.small(backgroundColor: Colors.deepPurple, onPressed: _createNewSession, child: const Icon(Icons.add, color: Colors.white))),
                ],
              ),
            ),
    );
  }
}

class HighlightCodeBuilder extends MarkdownElementBuilder {
  final Function(String) onExplain;
  HighlightCodeBuilder({required this.onExplain});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) language = element.attributes['class']!.substring(9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              InkWell(
                onTap: () => onExplain(element.textContent),
                child: const Row(children: [Icon(Icons.lightbulb, size: 14, color: Colors.amberAccent), SizedBox(width: 4), Text('Explain', style: TextStyle(fontSize: 10, color: Colors.amberAccent))]),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
          child: HighlightView(
            element.textContent, language: language.isEmpty ? 'plaintext' : language, theme: vs2015Theme,
            padding: const EdgeInsets.all(12), textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ChatSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> messages;
  _ChatSearchDelegate(this.messages);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList();
  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = messages.where((m) => m['content'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final msg = results[index];
        return ListTile(
          leading: Icon(msg['role'] == 'user' ? Icons.person : Icons.smart_toy),
          title: Text(msg['content'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}
