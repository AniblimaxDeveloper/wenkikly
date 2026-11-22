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
      return 'Error: API Key tidak ditemukan. Silakan buka menu Settings dan masukkan API Key OpenRouter Anda.';
    }

    final prefs = await SharedPreferences.getInstance();
    final systemPrompt = prefs.getString('system_prompt') ?? '';
    final temperature = prefs.getDouble('temperature') ?? 0.7;

    // FITUR BARU: Cek jika user minta gambar
    if (messages.last['content']!.startsWith('/image ')) {
      final prompt = messages.last['content']!.replaceFirst('/image ', '');
      // Menggunakan Pollinations.ai (Gratis, tanpa API Key)
      final imageUrl = 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}?width=1024&height=1024&nologo=true';
      return '![Gambar AI]($imageUrl)';
    }

    List<Map<String, String>> finalMessages = [];
    if (systemPrompt.isNotEmpty) {
      finalMessages.add({'role': 'system', 'content': systemPrompt});
    }
    finalMessages.addAll(messages);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _getBackendModel(modelId),
          'messages': finalMessages,
          'temperature': temperature, // FITUR BARU: Suhu Kreativitas
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Tidak ada respons.';
      } else if (response.statusCode == 401) {
        return 'Error 401: API Key tidak valid atau sudah kedaluwarsa. Cek di menu Settings.';
      } else if (response.statusCode == 429) {
        return 'Error 429: Terlalu banyak permintaan (Rate Limit). Tunggu sebentar lalu coba lagi.';
      } else {
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'Gagal terhubung ke server AI. Periksa koneksi internet Anda.';
    }
  }

  String _getBackendModel(String whenModel) {
    if (whenModel.contains('Free') || whenModel.contains('when-1') || whenModel.contains('when-2')) {
      return 'meta-llama/llama-3.1-8b-instruct'; 
    } else if (whenModel.contains('when-go') || whenModel.contains('when-plus')) {
      return 'meta-llama/llama-3.1-70b-instruct'; 
    } else {
      return 'openai/gpt-4o-mini'; 
    }
  }
}
