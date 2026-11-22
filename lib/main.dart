import 'package:flutter/material.dart';
import 'models/ai_model.dart';
import 'services/ai_service.dart';

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
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final AIService _aiService = AIService();
  
  // State untuk model yang dipilih (Default: WHEN 1.0)
  AIModel _selectedModel = wenkiklyModels[0];

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Simulasi limit untuk paket Free
    if (!_selectedModel.isUnlimited && _messages.length >= 10) {
      _showLimitDialog();
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();

    final reply = await _aiService.sendMessage(_messages, _selectedModel.id);

    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _isLoading = false;
    });
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Tercapai'),
        content: const Text('Maaf, Anda telah mencapai batas pesan untuk paket Free. Silakan upgrade ke paket Go, Plus, Pro, Business, atau Ultra untuk akses unlimited.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
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
                            child: Text(
                              model.isUnlimited ? 'UNLIMITED' : 'LIMIT',
                              style: TextStyle(fontSize: 10, color: model.isUnlimited ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      subtitle: Text(model.description, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
                      onTap: () {
                        setState(() { _selectedModel = model; });
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
            Text(
              '${_selectedModel.name} (${_selectedModel.tier})',
              style: const TextStyle(fontSize: 12, color: Colors.deepPurpleAccent),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Ganti Model',
            onPressed: _showModelSelector,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.deepPurple.shade700 : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(msg['content']!, style: const TextStyle(fontSize: 15, height: 1.4)),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent)),
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
