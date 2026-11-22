import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('is_dark_mode') ?? true);
  }

  void _changeTheme(bool isDark) {
    setState(() => _isDarkMode = isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wenkikly AI',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A), foregroundColor: Colors.white, elevation: 0),
      ),
      home: ChatScreen(onThemeChanged: _changeTheme),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const ChatScreen({super.key, required this.onThemeChanged});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  AIModel _selectedModel = wenkiklyModels[0];
  bool _showScrollToBottom = false;

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
    _loadHistory();
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
    String cleanText = text.replaceAll(RegExp(r'[*#`_]'), ''); 
    await _flutterTts.speak(cleanText);
  }

  Future<void> _loadHistory() async {
    final sessions = await _storageService.loadSessions();
    setState(() {
      _sessions = sessions;
      if (_sessions.isNotEmpty) {
        _currentSession = _sessions.first;
        _selectedModel = wenkiklyModels.firstWhere((m) => m.id == _currentSession!.modelId, orElse: () => wenkiklyModels[0]);
      } else {
        _createNewSession();
      }
    });
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
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
      _currentSession!.messages.add({'role': 'user', 'content': messageText});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    _storageService.saveSessions(_sessions);

    final reply = await _aiService.sendMessage(_currentSession!.messages, _selectedModel.id);

    setState(() {
      _currentSession!.messages.add({'role': 'assistant', 'content': reply});
      _isLoading = false;
    });
    _scrollToBottom();
    _storageService.saveSessions(_sessions);
  }

  void _exportChat() {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;
    String text = "Wenkikly AI - ${_currentSession!.title}\n\n";
    for (var msg in _currentSession!.messages) {
      text += msg['role'] == 'user' ? "User: " : "AI: ";
      text += "${msg['content']}\n\n";
    }
    Share.share(text);
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

  // ... (Fungsi _showModelSelector() tetap sama persis seperti sebelumnya)
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
    
    return Scaffold(
      appBar: AppBar(
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onThemeChanged: widget.onThemeChanged))).then((_) => _loadHistory())
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF0F0F0F) : Colors.grey[200]),
              child: Center(child: Text('Riwayat Obrolan', style: Theme.of(context).textTheme.titleLarge)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: session.id == _currentSession?.id,
                    selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                    onTap: () {
                      setState(() {
                        _currentSession = session;
                        _selectedModel = wenkiklyModels.firstWhere((m) => m.id == session.modelId, orElse: () => wenkiklyModels[0]);
                      });
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
          : Stack(
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
                                    Text('Mulai percakapan dengan ${_selectedModel.name}', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 24),
                                    // FITUR BARU: Quick Prompts
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
                                return Align(
                                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                                    decoration: BoxDecoration(
                                      color: isUser ? Colors.deepPurple.shade700 : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        isUser 
                                          ? SelectableText(msg['content']!, style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.white : Colors.black87))
                                          : MarkdownBody(
                                              data: msg['content']!,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.white : Colors.black87),
                                                code: const TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent),
                                              ),
                                            ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (!isUser) ...[
                                              IconButton(icon: const Icon(Icons.volume_up, size: 16, color: Colors.grey), onPressed: () => _speak(msg['content']!)),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _isListening ? Colors.redAccent : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[300]),
                              child: IconButton(
                                icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.white : (isDark ? Colors.white54 : Colors.black54), size: 20),
                                onPressed: _listen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: _isListening ? 'Mendengarkan...' : 'Tanya ${_selectedModel.name}...',
                                  hintStyle: TextStyle(color: _isListening ? Colors.redAccent : (isDark ? Colors.white54 : Colors.black54)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                onPressed: _isLoading ? null : () => _sendMessage(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // FITUR BARU: Scroll to Bottom Button
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.deepPurple,
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }
}
