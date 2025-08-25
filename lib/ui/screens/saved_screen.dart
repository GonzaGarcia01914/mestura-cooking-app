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

  Widget list() {
    final s = AppLocalizations.of(context)!;
    final topPad = MediaQuery.of(context).padding.top + 72 + 8;

    return ListView.separated(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
      itemCount: _recipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final recipe = _recipes[i];
        final imageUrl = _normalizeImageUrl(recipe.image);

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
                // 👇 No reservamos espacio hasta que realmente cargue
                if (imageUrl != null) _ThumbIfLoadable(url: imageUrl),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                    ), // separación fija al texto
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
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
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
  }

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

/// Muestra un thumb SOLO si la imagen se resuelve; si no, no ocupa espacio.
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
