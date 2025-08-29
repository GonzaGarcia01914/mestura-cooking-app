import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe.dart';

class ShareRecipeService {
  static final _firestore = FirebaseFirestore.instance;

  // Configura tu dominio de Dynamic Links en Firebase Console
  // Usaremos un deep link con esquema personalizado: mestura://recipe?id=...
  static const String _scheme = 'mestura';
  static const String _deepHost = 'recipe';
  static const String _androidPackage = 'com.gonzalogarcia.mestura';
  static const String _iosBundleId = 'com.gonzalogarcia.mestura';

  static String _randomId([int len = 10]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static Future<String> _storeRecipe(RecipeModel recipe) async {
    final id = _randomId(12);
    await _firestore.collection('shared_recipes').doc(id).set(recipe.toJson());
    return id;
  }

  static Future<Uri> createShareLink(RecipeModel recipe) async {
    final id = await _storeRecipe(recipe);
    // Construimos un link de esquema personalizado. Requiere configuración en Android/iOS.
    final deep = Uri(
      scheme: _scheme,
      host: _deepHost,
      queryParameters: {'id': id},
    );
    return deep;
  }

  static Future<RecipeModel?> fetchSharedRecipeById(String id) async {
    final snap = await _firestore.collection('shared_recipes').doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return RecipeModel.fromJson(data);
  }
}
