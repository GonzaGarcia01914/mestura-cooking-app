import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../models/recipe.dart';

class OpenAIService {
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _moderationUrl = 'https://api.openai.com/v1/moderations';
  static const _model = 'gpt-3.5-turbo';

  Future<RecipeModel> generateRecipe(
    String query, {
    List<String>? restrictions,
    required String language,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OpenAI API key. Set it using --dart-define=OPENAI_API_KEY=your_key',
      );
    }

    // 👮 Moderation check ONLY on user input
    final isBlocked = await _isQueryFlagged(query);
    if (isBlocked) {
      throw Exception('Your input was flagged as inappropriate.');
    }

    final systemPrompt = '''
You are a chef assistant that returns only structured JSON responses and only speak about real food and edible things.
Do not include any explanations or markdown. Only output a pure JSON object like:
{
  "title": "...",
  "ingredients": ["...", "..."],
  "steps": ["...", "..."],
  "image": "https://..."
}
The content must be written entirely in ${language == 'es' ? 'Spanish' : 'English'}.
''';

    final userPrompt = _buildPrompt(query, restrictions);

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.8,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // ⚠️ Moderation check on the response content
      final isOutputBlocked = await _isQueryFlagged(content);
      if (isOutputBlocked) {
        throw Exception('Generated content was flagged as inappropriate.');
      }

      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      final jsonString = content.substring(jsonStart, jsonEnd + 1);
      final parsed = jsonDecode(jsonString);
      return RecipeModel.fromJson(parsed);
    } else {
      throw Exception('OpenAI error: ${response.body}');
    }
  }

  String _buildPrompt(String query, List<String>? restrictions) {
    final base = 'Create a detailed recipe for: $query.';
    if (restrictions != null && restrictions.isNotEmpty) {
      final banned = restrictions.join(', ');
      return '$base Do not include: $banned.';
    }
    return base;
  }

  // 🧠 Moderation helper
  Future<bool> _isQueryFlagged(String query) async {
    final response = await http.post(
      Uri.parse(_moderationUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'input': query}),
    );

    if (response.statusCode != 200) {
      throw Exception('Moderation API failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final result = data['results'][0];
    final flagged = result['flagged'] == true;

    // Categorías sensibles
    final scores = result['category_scores'] as Map<String, dynamic>;

    final threshold = 0.1;
    final sensitive = scores.entries.where((e) => e.value >= threshold);

    if (flagged || sensitive.isNotEmpty) {
      // Durante pruebas, podrías hacer debug:
      // print('Moderation blocked query: $query\nScores: $scores');
      return true;
    }

    return false;
  }
}
