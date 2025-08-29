import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../../models/recipe.dart';

class ShareRecipeService {
  static final _firestore = FirebaseFirestore.instance;

  // Configura tu dominio de Dynamic Links en Firebase Console
  static const String _domainPrefix = 'https://mestura.page.link'; // TODO: ajusta si es distinto
  static const String _deepHost = 'mestura.app'; // host simbólico para tu deep link
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
    final deepLink = Uri(
      scheme: 'https',
      host: _deepHost,
      path: '/recipe',
      queryParameters: {'id': id},
    );

    final params = DynamicLinkParameters(
      link: deepLink,
      uriPrefix: _domainPrefix,
      androidParameters: const AndroidParameters(packageName: _androidPackage),
      iosParameters: const IOSParameters(bundleId: _iosBundleId),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: recipe.title,
        imageUrl: recipe.image != null ? Uri.tryParse(recipe.image!) : null,
      ),
    );

    final short = await FirebaseDynamicLinks.instance.buildShortLink(params);
    return short.shortUrl;
  }

  static Future<RecipeModel?> fetchSharedRecipeById(String id) async {
    final snap = await _firestore.collection('shared_recipes').doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return RecipeModel.fromJson(data);
  }
}

