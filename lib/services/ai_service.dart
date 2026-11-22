import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class AIService {
  static const String _defaultApiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _envApiKey = String.fromEnvironment('OPENROUTER_API_KEY');

  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_api_key') ?? _envApiKey;
  }

  Future<String> _getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_api_url') ?? _defaultApiUrl;
  }

  Future<String> sendMessage(List<Map<String, dynamic>> messages, ChatSession session) async {
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty && !session.modelId.contains('local')) return 'Error: API Key tidak ditemukan. Buka Settings.';

    final prefs = await SharedPreferences.getInstance();
    final systemPrompt = session.systemPromptOverride ?? prefs.getString('system_prompt') ?? '';
    final temperature = session.temperatureOverride ?? prefs.getDouble('temperature') ?? 0.7;
    final timeoutSec = prefs.getInt('network_timeout') ?? 60;
    final apiUrl = await _getApiUrl();

    final lastContent = messages.last['content'];
    if (lastContent is String && lastContent.startsWith('/image ')) {
      final parts = lastContent.replaceFirst('/image ', '').split(' --ratio ');
      final prompt = parts[0];
      String ratio = '1024x1024';
      if (parts.length > 1) {
        if (parts[1] == '16:9') ratio = '1024x576';
        if (parts[1] == '9:16') ratio = '576x1024';
      }
      final imageUrl = 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}?width=${ratio.split('x')[0]}&height=${ratio.split('x')[1]}&nologo=true';
      return '![Gambar AI]($imageUrl)';
    }

    List<Map<String, dynamic>> finalMessages = [];
    if (systemPrompt.isNotEmpty) finalMessages.add({'role': 'system', 'content': systemPrompt});
    finalMessages.addAll(messages);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json', 
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode({
          'model': session.modelId.contains('local') ? session.modelId : _getBackendModel(session.modelId), 
          'messages': finalMessages, 
          'temperature': temperature
        }),
      ).timeout(Duration(seconds: timeoutSec));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Tidak ada respons.';
      } else if (response.statusCode == 401) {
        return 'Error 401: API Key tidak valid.';
      } else if (response.statusCode == 429) {
        return 'Error 429: Rate Limit.';
      } else {
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) return 'Error: Timeout. Server AI terlalu lama merespons.';
      return 'Gagal terhubung ke server AI. Cek koneksi / API URL.';
    }
  }

  Future<String> enhancePrompt(String prompt) async {
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) return prompt;

    try {
      final response = await http.post(
        Uri.parse(await _getApiUrl()),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'meta-llama/llama-3.1-8b-instruct',
          'messages': [
            {'role': 'system', 'content': 'Rewrite the user input to be a highly detailed, professional prompt. Output ONLY the prompt.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? prompt;
      }
      return prompt;
    } catch (e) {
      return prompt;
    }
  }

  String _getBackendModel(String whenModel) {
    if (whenModel.contains('Ultra') || whenModel.contains('Pro')) return 'openai/gpt-4o-mini'; 
    if (whenModel.contains('when-go') || whenModel.contains('when-plus')) return 'meta-llama/llama-3.1-70b-instruct'; 
    return 'meta-llama/llama-3.1-8b-instruct'; 
  }
}
