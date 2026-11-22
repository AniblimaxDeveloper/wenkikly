import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Parameter modelId ditambahkan
  Future<String> sendMessage(List<Map<String, String>> messages, String modelId) async {
    if (_apiKey.isEmpty) {
      return 'Error: API Key tidak ditemukan. Pastikan OPENROUTER_API_KEY sudah diatur.';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          // Kita petakan ID WHEN ke model API asli (misal: llama-3 atau gpt-4)
          // Untuk aplikasi demo ini, kita gunakan model open-source gratis/berbayar dari OpenRouter
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

  // Fungsi internal untuk memetakan WHEN ke model sungguhan
  String _getBackendModel(String whenModel) {
    // Kita gunakan model yang sangat murah/gratis untuk Free, dan model premium untuk Pro/Ultra
    if (whenModel.contains('Free') || whenModel.contains('when-1') || whenModel.contains('when-2')) {
      return 'meta-llama/llama-3-8b-instruct'; // Model gratis
    } else if (whenModel.contains('when-go') || whenModel.contains('when-plus')) {
      return 'meta-llama/llama-3-70b-instruct'; // Model menengah
    } else {
      return 'openai/gpt-4o-mini'; // Model canggih untuk Pro/Ultra (butuh saldo di OpenRouter)
    }
  }
}
