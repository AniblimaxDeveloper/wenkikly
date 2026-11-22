import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _envApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final localKey = prefs.getString('custom_api_key');
    if (localKey != null && localKey.isNotEmpty) return localKey;
    return _envApiKey;
  }

  Future<String> sendMessage(List<Map<String, dynamic>> messages, String modelId) async {
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) return 'Error: API Key tidak ditemukan. Buka Settings.';

    final prefs = await SharedPreferences.getInstance();
    final systemPrompt = prefs.getString('system_prompt') ?? '';
    final temperature = prefs.getDouble('temperature') ?? 0.7;

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
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({'model': _getBackendModel(modelId), 'messages': finalMessages, 'temperature': temperature}),
      );

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
      return 'Gagal terhubung ke server AI.';
    }
  }

  Future<String> enhancePrompt(String prompt) async {
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) return prompt;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
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
