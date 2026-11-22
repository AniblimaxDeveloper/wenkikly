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

  Future<String> sendMessage(List<Map<String, String>> messages, String modelId) async {
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) {
      return 'Error: API Key tidak ditemukan. Silakan buka menu Settings (ikon gear) dan masukkan API Key OpenRouter Anda.';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _getBackendModel(modelId), 
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Tidak ada respons.';
      } else {
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'Gagal terhubung ke server AI: $e';
    }
  }

  String _getBackendModel(String whenModel) {
    // Update model ID ke versi terbaru (3.1)
    if (whenModel.contains('Free') || whenModel.contains('when-1') || whenModel.contains('when-2')) {
      return 'meta-llama/llama-3.1-8b-instruct'; 
    } else if (whenModel.contains('when-go') || whenModel.contains('when-plus')) {
      return 'meta-llama/llama-3.1-70b-instruct'; 
    } else {
      return 'openai/gpt-4o-mini'; 
    }
  }
}
