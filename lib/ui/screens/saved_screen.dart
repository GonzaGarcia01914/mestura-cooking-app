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
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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
    setState(() {
      _recipes = saved;
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  // Widget _dismissBg(AlignmentGeometry align) {
  //   return Container(
  //     alignment: align,
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.red.withOpacity(0.90),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: const Icon(Icons.delete, color: Colors.white, size: 28),
  //   );
  // }

  String? _normalizeImageUrl(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final l = s.toLowerCase();
    if (l == 'null' || l == 'none' || l == 'n/a' || l == 'na' || l == '-') {
      return null;
    }
    final uri = Uri.tryParse(s);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top + 72 + 8;

    Widget emptyState() {
      final vh = MediaQuery.of(context).size.height;
      final contentHeight =
          (vh - topPad - 24).clamp(0, double.infinity).toDouble();

      return ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
        children: [
          SizedBox(
            height: contentHeight,
            child: Center(
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
          ),
        ],
      );
    }

    Widget _recipeCard(RecipeModel recipe, String? imageUrl) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) _ThumbIfLoadable(url: imageUrl),
              // El texto no tiene padding izquierdo extra: si no hay imagen, queda alineado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.ingredients.length} ${s.filterIngredients}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 76,
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget list() => AnimatedList(
          key: _listKey,
          controller: _scrollCtrl,
          padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
          initialItemCount: _recipes.length,
          itemBuilder: (_, i, animation) {
            final recipe = _recipes[i];
            final imageUrl = _normalizeImageUrl(recipe.image);

            return SizeTransition(
              sizeFactor: animation,
              child: Padding(
                padding: EdgeInsets.only(bottom: i == _recipes.length - 1 ? 0 : 12),
                child: Dismissible(
                  key: ValueKey(recipe.title),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  onDismissed: (_) {
                    final index = _recipes.indexOf(recipe);
                    final removed = _recipes.removeAt(index);
                    _listKey.currentState!.removeItem(
                      index,
                      (_, anim) => SizeTransition(
                        sizeFactor: anim,
                        child: FadeTransition(
                          opacity: anim,
                          child: _recipeCard(removed, _normalizeImageUrl(removed.image)),
                        ),
                      ),
                      duration: const Duration(milliseconds: 300),
                    );
                    StorageService().deleteRecipe(removed.title);
                    setState(() {});
                  },
                  child: _recipeCard(recipe, imageUrl),
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

/// Thumb que solo ocupa espacio si la imagen se ha resuelto correctamente.
class _ThumbIfLoadable extends StatefulWidget {
  const _ThumbIfLoadable({required this.url});
  final String url;

  @override
  State<_ThumbIfLoadable> createState() => _ThumbIfLoadableState();
}

class _ThumbIfLoadableState extends State<_ThumbIfLoadable> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final img = NetworkImage(widget.url);
    final stream = img.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _ready = true);
        stream.removeListener(listener);
      },
      onError: (error, _) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.url,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
