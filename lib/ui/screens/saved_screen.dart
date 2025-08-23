import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/storage_service.dart';
import '../../models/recipe.dart';
import 'recipe_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<RecipeModel> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final storage = StorageService();
    final saved = await storage.getSavedRecipes();
    setState(() => _recipes = saved);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.savedTitle)),
      body:
          _recipes.isEmpty
              ? Center(child: Text(s.noSavedRecipes))
              : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (_, i) {
                  final recipe = _recipes[i];
                  return ListTile(
                    title: Text(recipe.title),
                    subtitle: Text(
                      '${recipe.ingredients.length} ${s.filterIngredients}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeScreen(recipe: recipe),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
