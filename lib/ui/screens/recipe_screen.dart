import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/screens/loading_screen.dart';
import '../../models/recipe.dart';
import '../../core/services/openai_service.dart';
import '../../core/services/storage_service.dart';

class RecipeScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeScreen({super.key, required this.recipe});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late List<bool> _checked;
  bool _loading = false;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.recipe.ingredients.length, (_) => true);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'es';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  void _rewriteRecipe() async {
    final List<String> excluded = [];
    for (int i = 0; i < _checked.length; i++) {
      if (!_checked[i]) excluded.add(widget.recipe.ingredients[i]);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    try {
      final openai = OpenAIService();
      final newRecipe = await openai.generateRecipe(
        widget.recipe.title,
        restrictions: excluded,
        language: _locale.languageCode,
      );

      if (!mounted) return;

      Navigator.pop(context); // Cierra LoadingScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RecipeScreen(recipe: newRecipe)),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cierra LoadingScreen si hubo error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveRecipe() async {
    final storage = StorageService();
    await storage.saveRecipe(widget.recipe);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.savedConfirmation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final ingredients = widget.recipe.ingredients;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.recipe.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.recipe.image!,
                  fit: BoxFit.cover,
                  height: 180,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            if (widget.recipe.image != null) const SizedBox(height: 24),
            Text(
              widget.recipe.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              s.ingredientsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(
                ingredients.length,
                (index) => CheckboxListTile(
                  value: _checked[index],
                  onChanged: (val) {
                    setState(() => _checked[index] = val ?? true);
                  },
                  title: Text(ingredients[index]),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(s.stepsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                widget.recipe.steps.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${index + 1}. ${widget.recipe.steps[index]}'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _rewriteRecipe,
              child: Text(s.rewriteButton),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.bookmark_add),
              label: Text(s.saveButton),
            ),
          ],
        ),
      ),
    );
  }
}
