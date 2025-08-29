import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../ui/screens/recipe_screen.dart';
import '../navigation.dart';
import 'share_recipe_service.dart';

class DeepLinkService {
  static StreamSubscription<Uri?>? _sub;
  static AppLinks? _appLinks;

  static Future<void> init() async {
    _appLinks ??= AppLinks();
    await _handleInitialLink();
    _sub?.cancel();
    _sub = _appLinks!.uriLinkStream.listen((uri) {
      if (uri != null) _handleLink(uri);
    }, onError: (_) {});
  }

  static Future<void> _handleInitialLink() async {
    _appLinks ??= AppLinks();
    final uri = await _appLinks!.getInitialLink();
    if (uri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLink(uri);
      });
    }
  }

  static Future<void> _handleLink(Uri link) async {
    try {
      // Admitimos esquemas personalizados: mestura://recipe?id=...
      final isRecipe = (link.scheme == 'mestura' && link.host == 'recipe') ||
          (link.scheme == 'https' && link.host.contains('mestura') && link.path == '/recipe');
      if (isRecipe && link.queryParameters['id'] != null) {
        final id = link.queryParameters['id']!;
        final RecipeModel? recipe = await ShareRecipeService.fetchSharedRecipeById(id);
        if (recipe != null) {
          final nav = appNavigatorKey.currentState;
          nav?.push(MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)));
        }
      }
    } catch (_) {
      // Silencio: no romper UX si link no es válido
    }
  }
}
