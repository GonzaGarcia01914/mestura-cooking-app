import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/recipe.dart';

class StorageService {
  static const _key = 'saved_recipes';

  Future<void> saveRecipe(RecipeModel recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList(_key) ?? [];

    // Evita duplicados por título
    if (saved.any((r) => jsonDecode(r)['title'] == recipe.title)) return;

    saved.add(jsonEncode(recipe.toJson()));
    await prefs.setStringList(_key, saved);
  }

  Future<List<RecipeModel>> getSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList(_key) ?? [];
    return saved.map((r) => RecipeModel.fromJson(jsonDecode(r))).toList();
  }

  Future<void> deleteRecipe(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList(_key) ?? [];
    saved.removeWhere((r) => jsonDecode(r)['title'] == title);
    await prefs.setStringList(_key, saved);
  }
}
