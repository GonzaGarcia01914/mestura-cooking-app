import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/storage_service.dart';
import '../../models/recipe.dart';
import 'recipe_screen.dart';

// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/frosted_container.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _scrollCtrl = ScrollController();
  double _appBarTint = 0.0; // 0 = transparente, ~0.08 = máximo
  List<RecipeModel> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _scrollCtrl.addListener(() {
      const maxTint = 0.08;
      final off = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
      final t = (off / 48).clamp(0.0, 1.0) * maxTint;
      if ((t - _appBarTint).abs() > 0.004) setState(() => _appBarTint = t);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    final saved = await StorageService().getSavedRecipes();
    if (!mounted) return;
    setState(() => _recipes = saved);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top + 72 + 8;

    Widget emptyState() => ListView(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      children: [
        Center(
          child: FrostedContainer(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border, size: 48, color: cs.primary),
                const SizedBox(height: 10),
                Text(
                  s.noSavedRecipes,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    Widget list() => ListView.separated(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      itemCount: _recipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final recipe = _recipes[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)),
            );
          },
          child: FrostedContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    recipe.image ?? '',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          width: 76,
                          height: 76,
                          color: cs.surfaceVariant.withOpacity(0.6),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recipe.ingredients.length} ${s.filterIngredients}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        );
      },
    );

    return AppScaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar(
        title: Text(s.savedTitle),
        blurSigma: _appBarTint > 0 ? 6 : 0,
        tintOpacity: _appBarTint,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecipes,
        child: _recipes.isEmpty ? emptyState() : list(),
      ),
    );
  }
}
