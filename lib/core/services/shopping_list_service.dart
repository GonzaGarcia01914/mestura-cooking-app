import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/shopping_item.dart';

class ShoppingListService {
  static const _key = 'shopping_list_v1';

  Future<List<ShoppingItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? const <String>[];
    return rawList
        .map((e) {
          try {
            return ShoppingItem.fromJson(jsonDecode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ShoppingItem>()
        .toList();
  }

  Future<void> save(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

