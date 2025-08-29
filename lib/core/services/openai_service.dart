import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import '../../models/recipe.dart';
import 'preferences_service.dart';
import '../../models/preferences.dart';

class OpenAIService {
  // Región preferida (donde DESPLEGASTE). Cambia si es otra.
  static const String _primaryRegion = 'europe-west1';
  static const String _fallbackRegion = 'us-central1'; // retry si NOT_FOUND

  FirebaseFunctions _fx(String region) =>
      FirebaseFunctions.instanceFor(region: region);

  // Advanced options set from UI
  int? timeLimitMinutes;
  String? skillLevel; // 'basic' | 'standard' | 'elevated'

  // ----- Infra común ---------------------------------------------------------

  Future<void> _ensureAuth() async {
    // 1) Asegura usuario
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    // Avoid forcing token refresh on every call; let Firebase cache handle it
    await auth.currentUser!.getIdToken();

    // 2) Asegura App Check (fuerza obtener token válido)
    try {
      // Try without forcing refresh first; fallback once if needed
      await FirebaseAppCheck.instance.getToken(false);
    } catch (e) {
      debugPrint('[AppCheck] getToken error: $e');
      // Si falla, reintenta una vez tras breve espera
      await Future.delayed(const Duration(milliseconds: 400));
      await FirebaseAppCheck.instance.getToken(true);
    }
  }

  Future<dynamic> _call(
    String name,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _ensureAuth();

    Future<dynamic> invoke(String region) async {
      final callable = _fx(
        region,
      ).httpsCallable(name, options: HttpsCallableOptions(timeout: timeout));
      final res = await callable.call(data);
      return res.data;
    }

    try {
      return await invoke(_primaryRegion);
    } on FirebaseFunctionsException catch (e) {
      // Si la función no existe en esa región, reintenta en us-central1
      if (e.code == 'not-found' && _primaryRegion != _fallbackRegion) {
        debugPrint(
          '[Functions] "$name" not found in $_primaryRegion → retry in $_fallbackRegion',
        );
        return await invoke(_fallbackRegion);
      }
      rethrow;
    }
  }

  // ----- API pública ---------------------------------------------------------

  Future<bool> isFood(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;

    try {
      final d = await _call('isFood', {
        'query': trimmed,
      }, timeout: const Duration(seconds: 20));

      if (d is bool) return d;
      if (d is String) return d.toLowerCase().trim() == 'yes';
      if (d is Map && d['ok'] == true) return true;
      return false;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[isFood] ${e.code} ${e.message}');
      rethrow;
    }
  }

  Future<RecipeModel> generateRecipe(
    String query, {
    List<String>? restrictions,
    required String language,
    bool requireFoodCheck = false,
    bool generateImage = false,
    String imageSize = '1024x1024',
    int? servings,
    bool includeMacros = false, // ⭐ nuevo
    int? maxCaloriesKcal, // ⭐ nuevo
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw Exception('Query is empty.');
    }

    if (requireFoodCheck && !(await isFood(trimmed))) {
      throw Exception(
        language == 'es'
            ? 'Vamos a limitarnos a cosas comestibles.'
            : 'Let’s stick to edible things.',
      );
    }

    final FoodPreferences prefs = await PreferencesService().load();
    final payload = <String, dynamic>{
      'query': trimmed,
      'language': language,
      if (restrictions != null && restrictions.isNotEmpty)
        'restrictions': restrictions,
      if (servings != null && servings > 0) 'servings': servings,
      'generateImage': generateImage,
      'imageSize': imageSize,
      if (includeMacros) 'includeMacros': true, // ⭐
      if (maxCaloriesKcal != null) 'maxCaloriesKcal': maxCaloriesKcal, // ⭐
    };
    payload['preferences'] = prefs.toJson();
    // Inject advanced options if set via UI
    if (timeLimitMinutes != null) {
      payload['timeLimitMinutes'] = timeLimitMinutes;
    }
    if (skillLevel != null && skillLevel!.trim().isNotEmpty) {
      payload['skillLevel'] = skillLevel!.trim();
    }

    dynamic data;
    try {
      data = await _call('generateRecipe', payload);
    } on FirebaseFunctionsException catch (e) {
      // Fallback a otra función si tu backend la nombró distinto
      if (e.code == 'not-found') {
        data = await _call('openaiChat', payload);
      } else {
        debugPrint('[generateRecipe] ${e.code} ${e.message}');
        rethrow;
      }
    }

    // Normalización de respuesta (string JSON o map)
    Map<String, dynamic> obj;
    if (data is Map && data.containsKey('title')) {
      obj = Map<String, dynamic>.from(data);
    } else if (data is Map && data['content'] is String) {
      obj = _strictParseJson(data['content'] as String);
    } else if (data is String) {
      obj = _strictParseJson(data);
    } else {
      throw Exception('Invalid response from backend.');
    }

    // 👉 Construye directamente el modelo usando fromJson (compatible con toJson/camelCase)
    final recipe = RecipeModel.fromJson(obj);

    // Ajuste final: validar y normalizar imagen
    recipe.image = _normalizeImageUrl(recipe.image);

    if (recipe.title.trim().isEmpty ||
        recipe.ingredients.isEmpty ||
        recipe.steps.isEmpty) {
      throw Exception('Invalid recipe format from backend.');
    }

    return recipe;
  }

  // ----- Helpers -------------------------------------------------------------

  // List<String> _toStringList(dynamic v) {
  //   if (v is List) {
  //     return v
  //         .where((e) => e != null)
  //         .map((e) => e.toString().trim())
  //         .where((s) => s.isNotEmpty)
  //         .toList(growable: false);
  //   }
  //   return const <String>[];
  // }

  String? _normalizeImageUrl(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final l = s.toLowerCase();
    if (l == 'null' || l == 'none' || l == 'n/a' || l == 'na' || l == '-') {
      return null;
    }
    final uri = Uri.tryParse(s);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return s;
  }

  Map<String, dynamic> _strictParseJson(String raw) {
    var s = raw.trim();
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
}
