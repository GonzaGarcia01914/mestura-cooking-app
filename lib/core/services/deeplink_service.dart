import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../ui/screens/recipe_screen.dart';
import '../navigation.dart';
import 'share_recipe_service.dart';

class DeepLinkService {
  static StreamSubscription? _sub;

  static Future<void> init() async {
    await _handleInitialLink();
    _sub?.cancel();
    _sub = FirebaseDynamicLinks.instance.onLink.listen((data) {
      _handleLink(data.link);
    });
  }

  static Future<void> _handleInitialLink() async {
    final data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data?.link != null) {
      // Empuja tras primer frame para asegurar navigatorKey
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLink(data!.link);
      });
    }
  }

  static Future<void> _handleLink(Uri link) async {
    try {
      if (link.path == '/recipe' && link.queryParameters['id'] != null) {
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

