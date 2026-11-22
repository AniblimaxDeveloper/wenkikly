import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/ai_model.dart';
import 'models/chat_session.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const WenkiklyApp());
}

class WenkiklyApp extends StatelessWidget {
  const WenkiklyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wenkikly AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  bool _isLoading = false;
  AIModel _selectedModel = wenkiklyModels[0];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentSession == null) return;

    if (!_selectedModel.isUnlimited && _currentSession!.messages.length >= 10) {
      _showLimitDialog();
      return;
    }

    setState(() {
      if (_currentSession!.messages.isEmpty) {
        _currentSession!.title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      }
      _currentSession!.messages.add({'role': 'user', 'content': text});
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

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Tercapai'),
        content: const Text('Batas pesan untuk paket Free telah habis. Silakan ganti ke model Unlimited (Go, Plus, Pro, Business, Ultra).'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Pilih Model Wenkikly', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: wenkiklyModels.length,
                  itemBuilder: (context, index) {
                    final model = wenkiklyModels[index];
                    final isSelected = model.id == _selectedModel.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[800],
                        child: Icon(model.icon, color: Colors.white, size: 20),
                      ),
                      title: Row(
                        children: [
                          Text(model.name, style: TextStyle(color: isSelected ? Colors.deepPurpleAccent : Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: model.isUnlimited ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(model.isUnlimited ? 'UNLIMITED' : 'LIMIT', style: TextStyle(fontSize: 10, color: model.isUnlimited ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      subtitle: Text(model.description, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
                      onTap: () {
                        setState(() { 
                          _selectedModel = model; 
                          _currentSession!.modelId = model.id;
                        });
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
          IconButton(icon: const Icon(Icons.add_comment_outlined), tooltip: 'Chat Baru', onPressed: _createNewSession),
          IconButton(icon: const Icon(Icons.swap_horiz), tooltip: 'Ganti Model', onPressed: _showModelSelector),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0F0F0F)),
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
          : Column(
              children: [
                Expanded(
                  child: _currentSession!.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('Mulai percakapan dengan ${_selectedModel.name}', style: const TextStyle(color: Colors.white54)),
                            ],
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
                                  color: isUser ? Colors.deepPurple.shade700 : const Color(0xFF2C2C2C),
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
                                      ? SelectableText(msg['content']!, style: const TextStyle(fontSize: 15, height: 1.4))
                                      : MarkdownBody(
                                          data: msg['content']!,
                                          styleSheet: MarkdownStyleSheet(
                                            p: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white),
                                            code: const TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent),
                                          ),
                                        ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: msg['content']!));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disalin ke clipboard'), duration: Duration(seconds: 1)));
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
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent)),
                        SizedBox(width: 12),
                        Text('Wenkikly sedang berpikir...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Tanya ${_selectedModel.name}...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2C),
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
                            onPressed: _isLoading ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
