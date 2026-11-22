import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class StorageService {
  static const String _keySessions = 'wenkikly_sessions';

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_keySessions, encoded);
  }

  Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_keySessions);
    if (encoded == null || encoded.isEmpty) return [];
    
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => ChatSession.fromJson(e)).toList();
  }

  // FITUR BARU: Statistik
  Future<void> incrementStats(int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    int currentMessages = prefs.getInt('total_messages') ?? 0;
    int currentTokens = prefs.getInt('total_tokens') ?? 0;
    
    await prefs.setInt('total_messages', currentMessages + 1);
    await prefs.setInt('total_tokens', currentTokens + tokens);
  }

  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'messages': prefs.getInt('total_messages') ?? 0,
      'tokens': prefs.getInt('total_tokens') ?? 0,
    };
  }
}
