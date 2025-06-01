import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../models/recipe.dart';

class OpenAIService {
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-3.5-turbo';

  Future<RecipeModel> generateRecipe(
    String query, {
    List<String>? restrictions,
    required String language, // ← El idioma se requiere explícitamente
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OpenAI API key. Set it using --dart-define=OPENAI_API_KEY=your_key',
      );
    }

    final systemPrompt = '''
You are a chef assistant that returns only structured JSON responses.
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
}
