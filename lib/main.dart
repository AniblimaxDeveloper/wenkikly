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
import 'dart:ui';
import 'dart:convert';
import 'models/ai_model.dart';
import 'models/chat_session.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'screens/auth_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/about_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WenkiklyApp());
}

class WenkiklyApp extends StatefulWidget {
  const WenkiklyApp({super.key});
  @override
  State<WenkiklyApp> createState() => _WenkiklyAppState();
}

class _WenkiklyAppState extends State<WenkiklyApp> {
  bool _isLoggedIn = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    if (mounted) setState(() => _isLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wenkikly AI',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true, 
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark), 
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0),
      ),
      home: _isLoggedIn 
        ? ChatScreen(onLogout: () { _authService.signOut(); _checkLogin(); })
        : AuthScreen(onLoginSuccess: _checkLogin),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ChatScreen({super.key, required this.onLogout});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final SubscriptionService _subService = SubscriptionService();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isZenMode = false;
  bool _isAutoTts = false;
  bool _isHaptics = true;
  bool _isEnhancing = false;
  bool _isFullWidth = false;
  bool _isAutoScroll = true;
  bool _isSelectionMode = false;
  bool _isAutoTranslate = false;
  Set<int> _selectedIndices = {};
  String _timeFormat = '24h';
  String _quotedMessage = ''; 
  String _currentFolder = 'General';
  String _searchQuery = '';

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  AIModel _selectedModel = wenkiklyModels[0];
  bool _showScrollToTop = false;
  XFile? _pickedImage;
  String _selectedRatio = '1:1';
  String _tier = 'free';

  final List<String> _quickPrompts = ["Buatkan kode Flutter UI login.", "Jelaskan AI dengan sederhana.", "Tulis artikel teknologi.", "Buat puisi senja."];

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

  void _initTts() async => await _flutterTts.setLanguage("id-ID");

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _storageService.loadSessions();
    final actualTier = await _subService.getCurrentTier();
    
    setState(() {
      _tier = actualTier;
      _isAutoTts = prefs.getBool('auto_tts_enabled') ?? false;
      _isHaptics = prefs.getBool('haptics_enabled') ?? true;
      _isFullWidth = prefs.getBool('is_full_width') ?? false;
      _isAutoScroll = prefs.getBool('is_auto_scroll') ?? true;
      _isAutoTranslate = prefs.getBool('auto_translate') ?? false;
      _timeFormat = prefs.getString('time_format') ?? '24h';
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

  void _haptic() { if (_isHaptics) HapticFeedback.lightImpact(); }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) setState(() => _pickedImage = image);
  }

  void _createNewSession() {
    final newSession = ChatSession(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Obrolan Baru', messages: [], modelId: _selectedModel.id, folder: _currentFolder);
    setState(() { _sessions.insert(0, newSession); _currentSession = newSession; _controller.clear(); _quotedMessage = ''; _isSelectionMode = false; _selectedIndices.clear(); });
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

  void _togglePinSession(String id) {
    setState(() {
      final index = _sessions.indexWhere((s) => s.id == id);
      if (index != -1) _sessions[index].isPinned = !_sessions[index].isPinned;
    });
    _storageService.saveSessions(_sessions);
  }

  void _archiveSession(String id) {
    setState(() {
      final index = _sessions.indexWhere((s) => s.id == id);
      if (index != -1) _sessions[index].isArchived = !_sessions[index].isArchived;
    });
    _storageService.saveSessions(_sessions);
  }

  void _togglePinMessage(int index) {
    setState(() {
      _currentSession!.messages[index]['isPinned'] = !(_currentSession!.messages[index]['isPinned'] ?? false);
    });
    _storageService.saveSessions(_sessions);
    _haptic();
  }

  void _addReaction(int index, String emoji) {
    setState(() {
      _currentSession!.messages[index]['reaction'] = emoji;
    });
    _storageService.saveSessions(_sessions);
    _haptic();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) _selectedIndices.remove(index);
      else _selectedIndices.add(index);
      if (_selectedIndices.isEmpty) _isSelectionMode = false;
    });
  }

  Future<void> _enhanceCurrentPrompt() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isEnhancing = true);
    final enhanced = await _aiService.enhancePrompt(text);
    if (mounted) {
      setState(() { _controller.text = enhanced; _isEnhancing = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt disempurnakan!')));
    }
  }

  Future<void> _exportChat() async {
    if (_currentSession == null || _currentSession!.messages.isEmpty) return;
    String text = "# ${_currentSession!.title}\n\n";
    for (var msg in _currentSession!.messages) { text += msg['role'] == 'user' ? "### User\n" : "### AI\n"; text += "${msg['content']}\n\n---\n\n"; }
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Wenkikly_${_currentSession!.id}.md');
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], text: 'Ekspor Chat Wenkikly');
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ekspor: $e'))); 
    }
  }

  void _scrollToTop() => _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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

  void _showChatStats() {
    if (_currentSession == null) return;
    int totalMsgs = _currentSession!.messages.length;
    int totalWords = 0;
    for (var msg in _currentSession!.messages) { totalWords += msg['content'].toString().split(' ').length; }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Statistik Obrolan', style: TextStyle(color: Colors.white)),
        content: Text('Total Pesan: $totalMsgs\nTotal Kata: $totalWords', style: const TextStyle(color: Colors.white70)),
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
    if (_tier == 'free' && _currentSession!.messages.length >= 10) { _showLimitDialog(); return; }

    _haptic();
    String finalText = messageText.startsWith('/image ') ? '$messageText --ratio $_selectedRatio' : messageText;
    if (_quotedMessage.isNotEmpty) {
      finalText = "> $_quotedMessage\n\n$finalText";
      _quotedMessage = '';
    }
    if (_isAutoTranslate) finalText = "Translate this to the requested language: $finalText";

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
      _currentSession!.messages.add({'role': 'user', 'content': displayContent, 'timestamp': DateTime.now().toIso8601String(), 'raw_api_content': apiContent, 'isPinned': false});
      _isLoading = true;
      _pickedImage = null;
    });
    
    _controller.clear();
    _storageService.saveSessions(_sessions);
    if (_isAutoScroll) _scrollToBottom();

    final apiMessages = _currentSession!.messages.map((m) => {'role': m['role'], 'content': m['raw_api_content'] ?? m['content']}).toList();
    final reply = await _aiService.sendMessage(apiMessages, _currentSession!);

    setState(() {
      _currentSession!.messages.add({'role': 'assistant', 'content': reply, 'timestamp': DateTime.now().toIso8601String(), 'isPinned': false});
      _isLoading = false;
    });
    
    _storageService.saveSessions(_sessions);
    if (_isAutoScroll) _scrollToBottom();
    if (_isAutoTts && !reply.startsWith('Error')) _speak(reply);
  }

  void _showLimitDialog() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Limit Tercapai', style: TextStyle(color: Colors.white)), 
        content: const Text('Batas pesan paket Free habis. Ganti ke Unlimited.', style: TextStyle(color: Colors.white70)), 
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))]
      )
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF1E1E2C), 
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.7, maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Pilih Model Wenkikly', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            Expanded(
              child: ListView.builder(
                controller: scrollController, itemCount: wenkiklyModels.length,
                itemBuilder: (context, index) {
                  final model = wenkiklyModels[index];
                  final isSelected = model.id == _selectedModel.id;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: isSelected ? Colors.deepPurpleAccent : Colors.grey[800], child: Icon(model.icon, color: Colors.white, size: 20)),
                    title: Row(children: [Text(model.name, style: TextStyle(color: isSelected ? Colors.deepPurpleAccent : Colors.white, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: model.isUnlimited ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(model.isUnlimited ? 'UNLIMITED' : 'LIMIT', style: TextStyle(fontSize: 10, color: model.isUnlimited ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)))]),
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isZenMode ? null : PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
              title: GestureDetector(
                onLongPress: _showModelSelector,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wenkikly AI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
                    Text('${_selectedModel.name} • ~$totalTokens tk', style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent)),
                  ],
                ),
              ),
              actions: [
                if (!_isSelectionMode) ...[
                  IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: _ChatSearchDelegate(_currentSession!.messages))),
                  IconButton(icon: const Icon(Icons.summarize), onPressed: _summarizeChat),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'export') _exportChat();
                      if (val == 'stats') _showChatStats();
                      if (val == 'backup') _backupChats();
                      if (val == 'restore') _restoreChats();
                      if (val == 'premium') Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(onPaymentSuccess: () { Navigator.pop(context); _loadSettings(); })));
                      if (val == 'about') Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                      if (val == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(onThemeChanged: (b,c){}, onBiometricChanged: (b){}, onLanguageChanged: (s){}, onFontSizeChanged: (d){}))).then((_) => _loadSettings());
                      if (val == 'logout') widget.onLogout();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'export', child: Text('Ekspor Chat (MD)')),
                      const PopupMenuItem(value: 'stats', child: Text('Statistik Chat')),
                      const PopupMenuItem(value: 'backup', child: Text('Backup ke Clipboard')),
                      const PopupMenuItem(value: 'restore', child: Text('Restore dari Clipboard')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'premium', child: Text('Upgrade Premium')),
                      const PopupMenuItem(value: 'about', child: Text('Tentang Aplikasi')),
                      const PopupMenuItem(value: 'settings', child: Text('Pengaturan')),
                      const PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                  ),
                ] else ...[
                  IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () {
                    setState(() {
                      for (int i in _selectedIndices.toList()..sort((a,b)=>b.compareTo(a))) { _currentSession!.messages.removeAt(i); }
                      _selectedIndices.clear(); _isSelectionMode = false;
                    });
                    _storageService.saveSessions(_sessions);
                  }),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedIndices.clear(); })),
                ]
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0F).withOpacity(0.9),
            border: const Border(right: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0F0C29), Color(0xFF302B63)]),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Riwayat Obrolan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Paket: ${_tier.toUpperCase()}', style: TextStyle(fontSize: 12, color: _tier == 'free' ? Colors.orangeAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    if (session.isArchived) return const SizedBox.shrink(); // Sembunyikan yg diarsip
                    return ListTile(
                      leading: Icon(session.isPinned ? Icons.push_pin : Icons.chat_bubble_outline, size: 20, color: session.isPinned ? Colors.amberAccent : Colors.white),
                      title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                      selected: session.id == _currentSession?.id,
                      selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'pin') _togglePinSession(session.id);
                          if (val == 'archive') _archiveSession(session.id);
                          if (val == 'delete') _deleteSession(session.id);
                        },
                        itemBuilder: (c) => [
                          PopupMenuItem(value: 'pin', child: Text(session.isPinned ? 'Unpin' : 'Pin')),
                          PopupMenuItem(value: 'archive', child: Text('Archive')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                      onTap: () { setState(() { _currentSession = session; _selectedModel = wenkiklyModels.firstWhere((m) => m.id == session.modelId, orElse: () => wenkiklyModels[0]); }); Navigator.pop(context); },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0B0F), Color(0xFF1A1A2E), Color(0xFF0B0B0F)]),
        ),
        child: _currentSession == null
            ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
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
                                      Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurpleAccent.withOpacity(0.5)),
                                      const SizedBox(height: 24),
                                      Text('Mulai percakapan dengan ${_selectedModel.name}', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                                      const SizedBox(height: 32),
                                      Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: _quickPrompts.map((prompt) => ActionChip(label: Text(prompt, style: const TextStyle(fontSize: 12, color: Colors.white)), onPressed: () => _sendMessage(text: prompt), backgroundColor: Colors.white.withOpacity(0.1), side: BorderSide(color: Colors.white.withOpacity(0.2)))).toList()),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController, 
                                  padding: const EdgeInsets.only(top: 100, bottom: 160, left: 16, right: 16), 
                                  itemCount: _currentSession!.messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = _currentSession!.messages[index];
                                    final isUser = msg['role'] == 'user';
                                    final timeStr = DateFormat('HH:mm').format(DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String()));
                                    final isImageUrl = msg['content'] != null && msg['content']!.contains('image.pollinations.ai');
                                    final isSelected = _selectedIndices.contains(index);
                                    
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(vertical: 8), 
                                      decoration: isSelected ? BoxDecoration(border: Border.all(color: Colors.deepPurpleAccent, width: 2), borderRadius: BorderRadius.circular(20)) : null,
                                      child: Align(
                                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                        child: GestureDetector(
                                          onLongPress: () {
                                            if (_isSelectionMode) _toggleSelection(index);
                                            else {
                                              _haptic();
                                              showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E2C), builder: (c) => Wrap(children: [
                                                ListTile(leading: const Icon(Icons.copy, color: Colors.white), title: const Text('Copy', style: TextStyle(color: Colors.white)), onTap: () { Clipboard.setData(ClipboardData(text: msg['content']!)); Navigator.pop(c); }),
                                                ListTile(leading: const Icon(Icons.reply, color: Colors.white), title: const Text('Quote Reply', style: TextStyle(color: Colors.white)), onTap: () { setState(() => _quotedMessage = msg['content']); Navigator.pop(c); }),
                                                ListTile(leading: const Icon(Icons.push_pin, color: Colors.amberAccent), title: const Text('Pin Message', style: TextStyle(color: Colors.white)), onTap: () { _togglePinMessage(index); Navigator.pop(c); }),
                                                ListTile(leading: const Icon(Icons.checklist, color: Colors.white), title: const Text('Select', style: TextStyle(color: Colors.white)), onTap: () { setState(() { _isSelectionMode = true; _selectedIndices.add(index); }); Navigator.pop(c); }),
                                                ListTile(leading: const Icon(Icons.emoji_emotions, color: Colors.white), title: const Text('React', style: TextStyle(color: Colors.white)), onTap: () {
                                                  showDialog(context: c, builder: (d) => AlertDialog(backgroundColor: const Color(0xFF1E1E2C), content: Wrap(spacing: 12, children: ['👍', '❤️', '😂', '😮', '😢'].map((e) => GestureDetector(onTap: () { _addReaction(index, e); Navigator.pop(d); Navigator.pop(c); }, child: Text(e, style: const TextStyle(fontSize: 30)))).toList())),
                                                );
                                                }),
                                              ]));
                                            }
                                          },
                                          onTap: () { if (_isSelectionMode) _toggleSelection(index); },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            constraints: BoxConstraints(maxWidth: _isFullWidth ? MediaQuery.of(context).size.width * 0.95 : MediaQuery.of(context).size.width * 0.85),
                                            decoration: BoxDecoration(
                                              gradient: isUser ? const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF3F51B5)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                                              color: isUser ? null : Colors.white.withOpacity(0.05),
                                              border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                                              borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: isUser ? const Radius.circular(20) : Radius.zero, bottomRight: isUser ? Radius.zero : const Radius.circular(20)),
                                              boxShadow: [BoxShadow(color: isUser ? Colors.deepPurple.withOpacity(0.3) : Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (msg['isPinned'] == true) const Row(children: [Icon(Icons.push_pin, size: 12, color: Colors.amberAccent), SizedBox(width: 4), Text('Pinned', style: TextStyle(fontSize: 10, color: Colors.amberAccent))]),
                                                if (msg['reaction'] != null) Text(msg['reaction'], style: const TextStyle(fontSize: 20)),
                                                if (isImageUrl)
                                                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(msg['content']!.split('(')[1].split(')')[0], fit: BoxFit.cover))
                                                else if (isUser) 
                                                  SelectableText(msg['content']!, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5))
                                                else
                                                  MarkdownBody(
                                                      data: msg['content']!,
                                                      styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5)),
                                                      builders: {'code': HighlightCodeBuilder(onExplain: (code) => _sendMessage(text: "Jelaskan kode berikut:\n\n$code"))},
                                                    ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                                    Row(children: [if (!isUser) IconButton(icon: const Icon(Icons.volume_up, size: 16, color: Colors.white54), onPressed: () => _speak(msg['content']!))]),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        if (_isLoading)
                          const Padding(padding: EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent)), SizedBox(width: 12), Text('Wenkikly sedang mengetik...', style: TextStyle(color: Colors.white54, fontSize: 12))])),
                        
                        if (!_isZenMode)
                          ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                                ),
                                child: SafeArea(
                                  child: Column(
                                    children: [
                                      if (_quotedMessage.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 12),
                                          decoration: const BoxDecoration(color: Colors.white10, border: Border(left: BorderSide(color: Colors.deepPurpleAccent, width: 4))),
                                          child: Row(children: [Expanded(child: Text(_quotedMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white54))), IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white54), onPressed: () => setState(() => _quotedMessage = ''))]),
                                        ),
                                      if (_pickedImage != null)
                                        Stack(children: [
                                          Container(height: 80, width: 80, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover))),
                                          Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => _pickedImage = null), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                                        ]),
                                      Row(
                                        children: [
                                          IconButton(icon: const Icon(Icons.add_photo_alternate, color: Colors.white54), onPressed: _pickImage),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: _controller, style: const TextStyle(color: Colors.white),
                                              maxLength: 4000,
                                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text('$currentLength/$maxLength', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                              decoration: InputDecoration(
                                                hintText: 'Tanya ${_selectedModel.name}...', hintStyle: const TextStyle(color: Colors.white38),
                                                filled: true, fillColor: Colors.white.withOpacity(0.1),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                suffixIcon: _isEnhancing ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(icon: const Icon(Icons.auto_fix_high, color: Colors.amberAccent), onPressed: _enhanceCurrentPrompt),
                                              ),
                                              onSubmitted: (_) => _sendMessage(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.deepPurpleAccent, Colors.blueAccent])),
                                            child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _isLoading ? null : () => _sendMessage())
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_showScrollToTop)
                      Positioned(bottom: 100, right: 16, child: FloatingActionButton.small(backgroundColor: Colors.deepPurpleAccent, onPressed: _scrollToTop, child: const Icon(Icons.arrow_upward, color: Colors.white))),
                  ],
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
              InkWell(onTap: () => onExplain(element.textContent), child: const Row(children: [Icon(Icons.lightbulb, size: 14, color: Colors.amberAccent), SizedBox(width: 4), Text('Explain', style: TextStyle(fontSize: 10, color: Colors.amberAccent))])),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
          child: HighlightView(element.textContent, language: language.isEmpty ? 'plaintext' : language, theme: vs2015Theme, padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
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
        return ListTile(leading: Icon(msg['role'] == 'user' ? Icons.person : Icons.smart_toy, color: Colors.white), title: Text(msg['content'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)));
      },
    );
  }
}
