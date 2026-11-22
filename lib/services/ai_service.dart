import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Kunci API diambil dari environment variable saat build,
  // bukan ditulis langsung di kode.
  static const String _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    if (_apiKey.isEmpty) {
      return 'Error: API Key tidak ditemukan. Pastikan Anda sudah mengatur OPENROUTER_API_KEY di GitHub Secrets.';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3-8b-instruct', // Model default
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
}
