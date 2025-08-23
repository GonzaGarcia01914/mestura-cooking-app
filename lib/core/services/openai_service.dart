import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../models/recipe.dart';

class OpenAIService {
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _moderationUrl = 'https://api.openai.com/v1/moderations';
  static const _model = 'gpt-3.5-turbo';
  Future<bool> isFood(String query) => _isFood(query);

  Future<RecipeModel> generateRecipe(
    String query, {
    List<String>? restrictions,
    required String language,
    bool requireFoodCheck = false, // ⬅️ Nueva bandera
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OpenAI API key. Set it using --dart-define=OPENAI_API_KEY=your_key',
      );
    }

    if (requireFoodCheck) {
      final isActuallyFood = await _isFood(query);
      if (!isActuallyFood) {
        throw Exception(
          language == 'es'
              ? 'Vamos a limitarnos a cosas comestibles.'
              : 'Let’s stick to edible things.',
        );
      }
    }

    // 👮 Moderation check SOLO en el input
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

      // ⚠️ Moderation en la respuesta
      final isOutputBlocked = await _isQueryFlagged(content);
      if (isOutputBlocked) {
        throw Exception('Generated content was flagged as inappropriate.');
      }

      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      final jsonString = content.substring(jsonStart, jsonEnd + 1);
      final parsed = jsonDecode(jsonString);
      final recipe = RecipeModel.fromJson(parsed);

      // 🖼️ Generación de imagen
      // final imagePrompt =
      //     'High-quality photorealistic image of a dish called "${recipe.title}", made with: ${recipe.ingredients.join(', ')}. Shot on a professional kitchen counter, natural lighting, focus on the food';
      // final imageUrl = await generateImage(imagePrompt);

      // recipe.image = imageUrl;

      return recipe;
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

  Future<String> generateImage(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024', // o 512x512 para carga más rápida
        'quality': 'standard',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Image generation failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['data'][0]['url'];
  }

  Future<bool> _isFood(String query) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a food filter. Reply with "yes" if the input is food or edible. Reply with "no" if it is not. Only respond with "yes" or "no", nothing else.',
          },
          {'role': 'user', 'content': 'Is this food? "$query"'},
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Food check failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content =
        data['choices'][0]['message']['content'].toLowerCase().trim();
    return content == 'yes';
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
