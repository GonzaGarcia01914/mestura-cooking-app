import 'package:shared_preferences/shared_preferences.dart';

class AdGate {
  static const _key = 'recipe_generation_count';
  static const every = 2;

  static Future<void> registerAction() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(_key) ?? 0;
    await prefs.setInt(_key, n + 1);
  }

  static Future<bool> shouldShowThisTime() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_key) ?? 0) + 1;
    await prefs.setInt(_key, next);
    return next % every == 0;
  }
}
