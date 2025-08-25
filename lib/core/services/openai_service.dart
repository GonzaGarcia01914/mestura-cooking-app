import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/recipe.dart';

class OpenAIService {
  // Clave por --dart-define=OPENAI_API_KEY=...
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Endpoints
  static const _chatUrl = 'https://api.openai.com/v1/chat/completions';
  static const _moderationUrl = 'https://api.openai.com/v1/moderations';

  // Modelos
  static const _chatModel = 'gpt-4o-mini';
  static const _moderationModel = 'omni-moderation-latest';

  // Placeholder si el modelo/no hay imagen
  // static const _fallbackImage =
  //     'https://picsum.photos/seed/food-plate/1024/768';

  Future<bool> isFood(String query) => _isFood(query);

  Future<RecipeModel> generateRecipe(
    String query, {
    List<String>? restrictions,
    required String language,
    bool requireFoodCheck = false,

    /// 🔽 Nuevo: controlas si generar imagen
    bool generateImage = false,
    String imageSize = '1024x1024',
  }) async {
    _ensureKey();

    // if (requireFoodCheck) {
    //   final ok = await _isFood(query);
    //   if (!ok) {
    //     throw Exception(
    //       language == 'es'
    //           ? 'Vamos a limitarnos a cosas comestibles.'
    //           : 'Let’s stick to edible things.',
    //     );
    //   }
    // }

    // Moderación SOLO del input
    if (await _isQueryFlagged(query)) {
      throw Exception('Your input was flagged as inappropriate.');
    }

    final systemPrompt = '''
You are a chef assistant. Return ONLY a single valid JSON object with this exact structure:
{
  "title": "string, non-empty",
  "ingredients": ["string", "..."],   // non-empty array of non-empty strings
  "steps": ["string", "..."],         // non-empty array of non-empty strings
  "image": "string URL or empty"      // optional; may be empty
}
Do NOT include any markdown, backticks, or explanations.
Write ALL content in ${language == 'es' ? 'Spanish' : 'English'} and only about real food.
''';

    final userPrompt = _buildPrompt(query, restrictions);

    final body = jsonEncode({
      'model': _chatModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.8,
      'max_tokens': 900,
    });

    final resp = await http.post(
      Uri.parse(_chatUrl),
      headers: _headers(),
      body: body,
    );
    if (resp.statusCode != 200) {
      throw _httpError('OpenAI chat', resp);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final raw = (data['choices']?[0]?['message']?['content'] ?? '').toString();

    // Moderación del output
    if (await _isQueryFlagged(raw)) {
      throw Exception('Generated content was flagged as inappropriate.');
    }

    // Parse estricto (debería venir como JSON limpio)
    final Map<String, dynamic> parsed = _strictParseJson(raw);

    // Validación mínima
    bool _validList(dynamic v) =>
        v is List &&
        v.isNotEmpty &&
        v.every((e) => e is String && e.trim().isNotEmpty);

    final title = (parsed['title'] ?? '').toString().trim();
    final ingredients = parsed['ingredients'];
    final steps = parsed['steps'];
    var image = (parsed['image'] ?? '').toString().trim();

    if (title.isEmpty || !_validList(ingredients) || !_validList(steps)) {
      throw Exception('Invalid recipe format from model. Please try again.');
    }

    // 🖼️ Imagen opcional controlada por flag
    if (generateImage) {
      try {
        final imgPrompt = _imagePromptFor(
          title: title,
          ingredients: List<String>.from(ingredients),
          lang: language,
        );
        final url = await this.generateImage(imgPrompt, size: imageSize);
        image = url; // sobrescribimos con nuestra imagen generada
      } catch (e) {
        debugPrint('[Images] Generation failed: $e');
        // if (image.isEmpty) image = _fallbackImage;
      }
    } else {
      // if (image.isEmpty) image = _fallbackImage;
    }

    final recipe = RecipeModel.fromJson({
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'image': image,
    });

    return recipe;
  }

  String _buildPrompt(String query, List<String>? restrictions) {
    final base =
        'Create a complete and practical recipe for: "$query". '
        'Include concise ingredient amounts and clear numbered steps.';
    if (restrictions != null && restrictions.isNotEmpty) {
      final banned = restrictions.join(', ');
      return '$base Avoid these ingredients: $banned.';
    }
    return base;
  }

  // === Generación de imagen (DALL·E 3)
  Future<String> generateImage(
    String prompt, {
    String size = '1024x1024',
  }) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: _headers(),
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': size,
        'quality': 'standard',
      }),
    );

    if (response.statusCode != 200) {
      throw _httpError('Image generation', response);
    }

    final data = jsonDecode(response.body);
    return data['data'][0]['url'];
  }

  String _imagePromptFor({
    required String title,
    required List<String> ingredients,
    required String lang,
  }) {
    final ing = ingredients.take(10).join(', ');
    final t =
        (lang == 'es')
            ? 'Fotografía profesional realista de comida'
            : 'Realistic professional food photography';
    return '$t of a dish called "$title". Ingredients: $ing. '
        'Natural lighting, on a clean table, high detail, shallow depth of field.';
  }

  // === Food check robusto ===
  Future<bool> _isFood(String query) async {
    final resp = await http.post(
      Uri.parse(_chatUrl),
      headers: _headers(),
      body: jsonEncode({
        'model': _chatModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a food filter. Reply with ONLY "yes" if the input is food or edible, otherwise ONLY "no".',
          },
          {'role': 'user', 'content': 'Is this food? "$query"'},
        ],
        'temperature': 0.0,
        'max_tokens': 2,
      }),
    );

    if (resp.statusCode != 200) {
      throw _httpError('Food check', resp);
    }

    final data = jsonDecode(resp.body);
    final content =
        (data['choices'][0]['message']['content'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    return content == 'yes';
  }

  // === Moderación ===
  Future<bool> _isQueryFlagged(String text) async {
    final resp = await http.post(
      Uri.parse(_moderationUrl),
      headers: _headers(),
      body: jsonEncode({'model': _moderationModel, 'input': text}),
    );

    if (resp.statusCode != 200) {
      throw _httpError('Moderation', resp);
    }

    final data = jsonDecode(resp.body);
    final result = (data['results'] as List).first;
    final flagged = result['flagged'] == true;
    return flagged == true;
  }

  // === Helpers ===
  void _ensureKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OpenAI API key. Set it using --dart-define=OPENAI_API_KEY=your_key',
      );
    }
  }

  Map<String, String> _headers() => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _strictParseJson(String raw) {
    var s = raw.trim();

    // Por si el modelo ignorara el response_format y metiera fences
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
      s = s.replaceAll(RegExp(r'```$', multiLine: true), '').trim();
      s = s.replaceAll('```', '').trim();
    }

    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception('Invalid model output: JSON not found.');
    }

    final jsonString = s.substring(start, end + 1);
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[OpenAI] JSON parse error: $e\n--- RAW ---\n$s');
      throw Exception('Invalid model output: JSON parse error.');
    }
  }

  Exception _httpError(String where, http.Response r) {
    String details = r.body;
    try {
      final decoded = jsonDecode(r.body);
      final msg = decoded['error']?['message'];
      final type = decoded['error']?['type'];
      final code = decoded['error']?['code'];
      final respId = decoded['id'] ?? decoded['response_id'];
      details =
          'status=${r.statusCode} message=$msg type=$type code=$code responseId=$respId';
    } catch (_) {}
    return Exception('$where failed: $details');
  }
}
