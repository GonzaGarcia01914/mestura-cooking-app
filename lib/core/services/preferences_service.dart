import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/preferences.dart';

class PreferencesService {
  static const _key = 'dietary_preferences_v1';

  Future<FoodPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const FoodPreferences();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return FoodPreferences.fromJson(map);
    } catch (_) {
      return const FoodPreferences();
    }
  }

  Future<void> save(FoodPreferences fp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(fp.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

