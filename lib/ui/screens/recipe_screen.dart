import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ui/screens/loading_screen.dart';
import '../../models/recipe.dart';
import '../../core/services/openai_service.dart';
import '../../core/services/storage_service.dart';

// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/frosted_container.dart';

class RecipeScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeScreen({super.key, required this.recipe});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late List<bool> _checked;
  final bool _loading = false;
  Locale? _locale;

  // === Nuevo: controlar opacidad del AppBar según scroll ===
  final _scrollCtrl = ScrollController();
  double _appBarTint = 0.0; // 0 = transparente, 0.08 = máximo

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.recipe.ingredients.length, (_) => true);
    _loadPreferences();

    _scrollCtrl.addListener(() {
      // entre 0 y ~48px empezamos a mostrar el tinte
      const maxTint = 0.08;
      final offset =
          _scrollCtrl.positions.isNotEmpty ? _scrollCtrl.offset : 0.0;
      final target = (offset / 48.0).clamp(0.0, 1.0) * maxTint;
      if ((target - _appBarTint).abs() > 0.004) {
        setState(() => _appBarTint = target);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'es';
    if (!mounted) return;
    setState(() => _locale = Locale(languageCode));
  }

  void _rewriteRecipe() async {
    final excluded = <String>[];
    for (var i = 0; i < _checked.length; i++) {
      if (!_checked[i]) excluded.add(widget.recipe.ingredients[i]);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    try {
      final openai = OpenAIService();
      final langCode =
          _locale?.languageCode ?? Localizations.localeOf(context).languageCode;

      final newRecipe = await openai.generateRecipe(
        widget.recipe.title,
        restrictions: excluded,
        language: langCode,
      );

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RecipeScreen(recipe: newRecipe)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
    final theme = Theme.of(context);
    final ingredients = widget.recipe.ingredients;
    final steps = widget.recipe.steps;

    return AppScaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar(
        title: Text(s.appTitle),
        leading: const BackButton(),
        // dinámico: transparente al inicio, translúcido en scroll
        blurSigma: _appBarTint > 0 ? 6 : 0,
        tintOpacity: _appBarTint,
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // deja el contenido por debajo del AppBar transparente
            SizedBox(height: MediaQuery.of(context).padding.top + 72 + 8),

            // Imagen de cabecera
            FrostedContainer(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    widget.recipe.image ?? '',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          alignment: Alignment.center,
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.5,
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.recipe.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 20),

            // Ingredientes
            FrostedContainer(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.ingredientsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    ingredients.length,
                    (i) => CheckboxListTile(
                      value: _checked[i],
                      onChanged:
                          (val) => setState(() => _checked[i] = val ?? true),
                      title: Text(ingredients[i]),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pasos
            FrostedContainer(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.stepsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    steps.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${i + 1}. ${steps[i]}'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            AppPrimaryButton(
              loading: _loading,
              onPressed: _rewriteRecipe,
              child: Text(s.rewriteButton),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.bookmark_add),
              label: Text(s.saveButton),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
