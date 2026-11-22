import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'models/ai_model.dart';
import 'models/chat_session.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const WenkiklyApp());
}

class WenkiklyApp extends StatefulWidget {
  const WenkiklyApp({super.key});
  @override
  State<WenkiklyApp> createState() => _WenkiklyAppState();
}

class _WenkiklyAppState extends State<WenkiklyApp> {
  bool _isDarkMode = true;
  bool _isBiometricEnabled = false;
  bool _isAuthenticated = false;
  Color _accentColor = Colors.deepPurple;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _accentColor = Color(prefs.getInt('accent_color') ?? 0xFF673AB7);
    });
    
    if (_isBiometricEnabled) {
      _authenticate();
    } else {
      setState(() => _isAuthenticated = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Pindai sidik jari untuk membuka Wenkikly AI',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      setState(() => _isAuthenticated = authenticated);
    } catch (e) {
      setState(() => _isAuthenticated = false);
    }
  }

  void _changeTheme(bool isDark) => setState(() => _isDarkMode = isDark);
  void _changeBiometric(bool enabled) => setState(() => _isBiometricEnabled = enabled);

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 80, color: _accentColor),
                const SizedBox(height: 20),
                const Text('Wenkikly Terkunci', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                  child: const Text('Buka dengan Sidik Jari'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Wenkikly AI',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light, 
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(seedColor: _accentColor), 
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0)
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true, 
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme), 
        colorScheme: ColorScheme.fromSeed(seedColor: _accentColor, brightness: Brightness.dark), 
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), 
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A), foregroundColor: Colors.white, elevation: 0)
      ),
      home: ChatScreen(onThemeChanged: _changeTheme, onBiometricChanged: _changeBiometric),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(bool) onBiometricChanged;
  const ChatScreen({super.key, required this.onThemeChanged, required this.onBiometricChanged});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isZenMode = false; // FITUR BARU: Zen Mode

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  AIModel _selectedModel = wenkiklyModels[0];
  bool _showScrollToBottom = false;
  String _searchQuery = '';
  List<String> _savedPrompts = [];

  final List<String> _quickPrompts = [
    "Buatkan kode Flutter untuk UI login.",
    "Jelaskan konsep AI dengan bahasa sederhana.",
    "Tulis artikel tentang masa depan teknologi.",
    "Buat puisi tentang senja."
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadSettings();
    _scrollController.addListener(() {
      if (_scrollController.offset < _scrollController.position.maxScrollExtent - 200) {
        if (!_showScrollToBottom) setState(() => _showScrollToBottom = true);
      } else {
        if (_showScrollToBottom) setState(() => _showScrollToBottom = false);
      }
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final prompts = prefs.getStringList('saved_prompts') ?? [];
    final sessions = await _storageService.loadSessions();
    
    setState(() {
      _savedPrompts = prompts;
      _sessions = sessions;
      if (_sessions.isNotEmpty) {
        _currentSession = _sessions.first;
        _selectedModel = wenkiklyModels.firstWhere((m) => m.id == _currentSession!.modelId, orElse: () => wenkiklyModels[0]);
      } else {
        _createNewSession();
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() => _controller.text = val.recognizedWords));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _speak(String text) async {
    String cleanText = text.replaceAll(RegExp(r'[*#`_]'), '').replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), ''); 
    await _flutterTts.speak(cleanText);
  }

  void _createNewSession() {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Obrolan Baru',
      messages: [],
      modelId: _selectedModel.id,
    );
    setState(() {
      _sessions.insert(0, newSession);
      _currentSession = newSession;
    });
    _storageService.saveSessions(_sessions);
  }

  void _deleteSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
      if (_currentSession?.id == id) {
        if (_sessions.isNotEmpty) {
          _currentSession = _sessions.first;
          _selectedModel = wenkiklyModels.firstWhere((m) => m.id == _currentSession!.modelId, orElse: () => wenkiklyModels[0]);
        } else {
          _createNewSession();
        }
      }
    });
    _storageService.saveSessions(_sessions);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _savePrompt() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_savedPrompts.contains(text)) {
      setState(() { _savedPrompts.add(text); });
      await prefs.setStringList('saved_prompts', _savedPrompts);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt disimpan!')));
    }
  }

  void _showSavedPrompts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: _savedPrompts.isEmpty 
          ? [const Text('Belum ada prompt tersimpan.', textAlign: TextAlign.center)]
          : _savedPrompts.map((prompt) => ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.deepPurple),
              title: Text(prompt),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() { _savedPrompts.remove(prompt); });
                  await prefs.setStringList('saved_prompts', _savedPrompts);
                  Navigator.pop(context);
                },
              ),
              onTap: () { setState(() { _controller.text = prompt; }); Navigator.pop(context); },
            )).toList(),
      ),
    );
  }

  Future<void> _sendMessage({String? text}) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty || _currentSession == null) return;

    if (!_selectedModel.isUnlimited && _currentSession!.messages.length >= 10) {
      _showLimitDialog();
      return;
    }

    setState(() {
      if (_currentSession!.messages.isEmpty) {
        _currentSession!.title = messageText.length > 25 ? '${messageText.substring(0, 25)}...' : messageText;
      }
      _currentSession!.messages.add({'role': 'user', 'content': messageText, 'timestamp': DateTime.now().toIso8601String()});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    _storageService.saveSessions(_sessions);

    final reply = await _aiService.sendMessage(_currentSession!.messages, _selectedModel.id);

    setState(() {
      _currentSession!.messages.add({'role': 'assistant', 'content': reply, 'timestamp': DateTime.now().toIso8601String()});
      _isLoading = false;
    });
    _scrollToBottom();
    _storageService.saveSessions(_sessions);
  }

  void _regenerateResponse() async {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;
    
    if (_currentSession!.messages.last['role'] == 'assistant') {
      setState(() { _currentSession!.messages.removeLast(); _isLoading = true; });
      _storageService.saveSessions(_sessions);

      final reply = await _aiService.sendMessage(_currentSession!.messages, _selectedModel.id);

      setState(() {
        _currentSession!.messages.add({'role': 'assistant', 'content': reply, 'timestamp': DateTime.now().toIso8601String()});
        _isLoading = false;
      });
      _scrollToBottom();
      _storageService.saveSessions(_sessions);
    }
  }

  // FITUR BARU: Ekspor ke File .txt
  Future<void> _exportChat() async {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;
    String text = "Wenkikly AI - ${_currentSession!.title}\n\n";
    for (var msg in _currentSession!.messages) {
      text += msg['role'] == 'user' ? "User: " : "AI: ";
      text += "${msg['content']}\n\n";
    }
    
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Wenkikly_${_currentSession!.id}.txt');
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], text: 'Ekspor Chat Wenkikly');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Tercapai'),
        content: const Text('Batas pesan untuk paket Free telah habis. Silakan ganti ke model Unlimited.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              const Padding(padding: EdgeInsets.all(16.0), child: Text('Pilih Model Wenkikly', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: wenkiklyModels.length,
                  itemBuilder: (context, index) {
                    final model = wenkiklyModels[index];
                    final isSelected = model.id == _selectedModel.id;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[800], child: Icon(model.icon, color: Colors.white, size: 20)),
                      title: Row(
                        children: [
                          Text(model.name, style: TextStyle(color: isSelected ? Colors.deepPurpleAccent : null, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: model.isUnlimited ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(model.isUnlimited ? 'UNLIMITED' : 'LIMIT', style: TextStyle(fontSize: 10, color: model.isUnlimited ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      subtitle: Text(model.description, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
                      onTap: () {
                        setState(() { _selectedModel = model; _currentSession!.modelId = model.id; });
                        _storageService.saveSessions(_sessions);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredSessions = _sessions.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      // FITUR BARU: Zen Mode menyembunyikan AppBar
      appBar: _isZenMode ? null : AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wenkikly AI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            Text('${_selectedModel.name} (${_selectedModel.tier})', style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), tooltip: 'Ekspor Chat', onPressed: _exportChat),
          IconButton(icon: const Icon(Icons.add_comment_outlined), tooltip: 'Chat Baru', onPressed: _createNewSession),
          IconButton(icon: const Icon(Icons.swap_horiz), tooltip: 'Ganti Model', onPressed: _showModelSelector),
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged, onBiometricChanged: widget.onBiometricChanged))).then((_) => _loadSettings())
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari obrolan...', prefixIcon: const Icon(Icons.search, size: 18), filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredSessions.isEmpty 
                ? const Center(child: Text('Tidak ada obrolan ditemukan', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, size: 20),
                        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        selected: session.id == _currentSession?.id,
                        selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () => _deleteSession(session.id)),
                        onTap: () {
                          setState(() { _currentSession = session; _selectedModel = wenkiklyModels.firstWhere((m) => m.id == session.modelId, orElse: () => wenkiklyModels[0]); });
                          Navigator.pop(context);
                        },
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
              // FITUR BARU: Tap 2x untuk keluar dari Zen Mode
              onDoubleTap: () => setState(() => _isZenMode = !_isZenMode),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: _currentSession!.messages.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple.withOpacity(0.5)),
                                      const SizedBox(height: 16),
                                      Text('Mulai percakapan dengan ${_selectedModel.name}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                                      const SizedBox(height: 8),
                                      const Text('Trik: Ketik /image [deskripsi] untuk membuat gambar!', style: TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
                                      const SizedBox(height: 24),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: _quickPrompts.map((prompt) => ActionChip(
                                          label: Text(prompt, style: const TextStyle(fontSize: 12)),
                                          onPressed: () => _sendMessage(text: prompt),
                                          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                                          side: BorderSide.none,
                                        )).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _currentSession!.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _currentSession!.messages[index];
                                  final isUser = msg['role'] == 'user';
                                  final isLastMessage = index == _currentSession!.messages.length - 1;
                                  
                                  final timeStr = msg['timestamp'] != null ? DateFormat('HH:mm').format(DateTime.parse(msg['timestamp']!)) : '';
                                  final tokenEstimate = (msg['content']!.length / 4).ceil();
                                  final isImageUrl = msg['content']!.contains('image.pollinations.ai');
                                  
                                  return Align(
                                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.all(12),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                                      decoration: BoxDecoration(
                                        color: isUser ? Colors.deepPurple.shade700 : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero, bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (isImageUrl)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                msg['content']!.split('(')[1].split(')')[0],
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const Center(child: CircularProgressIndicator());
                                                },
                                              ),
                                            )
                                          else if (isUser) 
                                            SelectableText(msg['content']!, style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.white : Colors.black87))
                                          else
                                            MarkdownBody(
                                                data: msg['content']!,
                                                styleSheet: MarkdownStyleSheet(
                                                  p: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.white : Colors.black87),
                                                  code: const TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent, fontFamily: 'monospace'),
                                                  codeblockDecoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                  const SizedBox(width: 8),
                                                  Text('~$tokenEstimate tk', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  if (!isUser) ...[
                                                    // FITUR BARU: Tombol Translate
                                                    IconButton(
                                                      icon: const Icon(Icons.g_translate, size: 16, color: Colors.grey), 
                                                      tooltip: 'Terjemahkan',
                                                      onPressed: () => _sendMessage(text: "Terjemahkan teks berikut ke Bahasa Indonesia: ${msg['content']}"),
                                                    ),
                                                    IconButton(icon: const Icon(Icons.volume_up, size: 16, color: Colors.grey), onPressed: () => _speak(msg['content']!)),
                                                    const SizedBox(width: 8),
                                                    if (isLastMessage)
                                                      IconButton(icon: const Icon(Icons.refresh, size: 16, color: Colors.deepPurpleAccent), onPressed: _regenerateResponse),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  IconButton(
                                                    icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                                    onPressed: () {
                                                      Clipboard.setData(ClipboardData(text: msg['content']!));
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disalin'), duration: Duration(seconds: 1)));
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent)),
                              const SizedBox(width: 12),
                              Text('Wenkikly sedang mengetik...', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                      // FITUR BARU: Sembunyikan input bar di Zen Mode
                      if (!_isZenMode)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12))),
                          child: SafeArea(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _isListening ? Colors.redAccent : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[300]),
                                  child: IconButton(icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.white : (isDark ? Colors.white54 : Colors.black54), size: 20), onPressed: _listen),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    maxLength: 4000,
                                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text('$currentLength/$maxLength', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                                    decoration: InputDecoration(
                                      hintText: _isListening ? 'Mendengarkan...' : 'Tanya ${_selectedModel.name}...',
                                      hintStyle: TextStyle(color: _isListening ? Colors.redAccent : (isDark ? Colors.white54 : Colors.black54)),
                                      filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Icons.bookmark_add_outlined, size: 20, color: Colors.deepPurpleAccent), tooltip: 'Simpan Prompt', onPressed: _savePrompt),
                                          IconButton(icon: const Icon(Icons.list, size: 20, color: Colors.grey), tooltip: 'Prompt Tersimpan', onPressed: _showSavedPrompts),
                                        ],
                                      ),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _isLoading ? null : () => _sendMessage()),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_showScrollToBottom)
                    Positioned(
                      bottom: 80, right: 16,
                      child: FloatingActionButton.small(backgroundColor: Colors.deepPurple, onPressed: _scrollToBottom, child: const Icon(Icons.arrow_downward, color: Colors.white)),
                    ),
                ],
              ),
            ),
    );
  }
}
