import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../l10n/app_localizations.dart';
import '../../core/services/storage_service.dart';
import '../../models/recipe.dart';
import 'recipe_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/share_recipe_service.dart';

// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/frosted_container.dart';
import '../responsive.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  double _appBarTint = 0.0; // 0 = transparente, ~0.08 = mÃƒÂ¡ximo
  List<RecipeModel> _recipes = <RecipeModel>[];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int? _pendingDeleteIndex;

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
    });
  }

  String _composeShareText(AppLocalizations s, String title, String link) {
    // Intenta usar el string generado si existe; si no, fallback localizado simple
    try {
      final dyn = s as dynamic;
      final fn = dyn.shareCookedText as dynamic;
      if (fn is Function) {
        final res = fn(title, link);
        if (res is String) return res;
      }
    } catch (_) {}
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'es':
        return '¡Acabo de cocinar "$title"! Prueba la app: $link';
      case 'pt':
        return 'Acabei de cozinhar "$title"! Experimente o app: $link';
      case 'fr':
        return 'Je viens de cuisiner "$title" ! Essaie l\'app : $link';
      case 'de':
        return 'Ich habe gerade "$title" gekocht! Probier die App aus: $link';
      case 'it':
        return 'Ho appena cucinato "$title"! Prova l\'app: $link';
      case 'pl':
        return 'Właśnie ugotowałem "$title"! Wypróbuj aplikację: $link';
      case 'ru':
        return 'Я только что приготовил(а) "$title"! Попробуй приложение: $link';
      case 'ja':
        return '「$title」を作りました！ アプリを試してね: $link';
      case 'ko':
        return '방금 "$title"를 만들었어요! 앱을 사용해 보세요: $link';
      case 'zh':
        return '我刚刚做了"$title"！来试试这个应用：$link';
      default:
        return 'I just cooked "$title"! Try the app: $link';
    }
  }

  Future<void> _shareSaved(RecipeModel recipe) async {
    final s = AppLocalizations.of(context)!;
    try {
      Uri? link;
      try {
        link = await ShareRecipeService.createShareLink(recipe);
      } catch (_) {
        link = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.gonzalogarcia.mestura',
        );
      }
      final text = _composeShareText(s, recipe.title, link.toString());
      await Share.share(text, subject: s.shareButton);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
    }
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= Responsive.tabletBreakpoint;

    Widget emptyState() {
      final vh = MediaQuery.of(context).size.height;
      final contentHeight =
          (vh - topPad - 24).clamp(0.0, double.infinity).toDouble();

      return ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.hPadding(context),
          topPad,
          Responsive.hPadding(context),
          24,
        ),
        children: [
          SizedBox(
            height: contentHeight,
            child: Center(
              child: FrostedContainer(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
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

    Widget recipeCard(RecipeModel recipe, String? imageUrl) {
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
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null) _ThumbIfLoadable(url: imageUrl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        children: [
                          TextSpan(text: recipe.title),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                onTap: () => _shareSaved(recipe),
                                customBorder: const CircleBorder(),
                                child: const Icon(
                                  Icons.share,
                                  size: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
              const SizedBox(
                height: 76,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 24,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget grid() => GridView.builder(
          padding: EdgeInsets.fromLTRB(
            Responsive.hPadding(context),
            topPad,
            Responsive.hPadding(context),
            24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth >= Responsive.desktopBreakpoint ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemCount: _recipes.length,
          itemBuilder: (ctx, i) {
            final recipe = _recipes[i];
            final imageUrl = _normalizeImageUrl(recipe.image);
            return Dismissible(
              key: ValueKey('grid-${recipe.title}-$i'),
              direction: DismissDirection.startToEnd,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              onDismissed: (_) {
                setState(() {
                  final removed = _recipes.removeAt(i);
                  StorageService().deleteRecipe(removed.title);
                });
              },
              child: recipeCard(recipe, imageUrl),
            );
          },
        );

    Widget list() => AnimatedList(
      key: _listKey,
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(
        Responsive.hPadding(context),
        topPad,
        Responsive.hPadding(context),
        24,
      ),
      initialItemCount: _recipes.length,
      itemBuilder: (_, i, animation) {
        final recipe = _recipes[i];
        final imageUrl = _normalizeImageUrl(recipe.image);
        final isPending = _pendingDeleteIndex == i;

        return SizeTransition(
          sizeFactor: animation,
          child: Padding(
            padding: EdgeInsets.only(bottom: i == _recipes.length - 1 ? 0 : 12),
            child: Dismissible(
              resizeDuration: null,
              key: ValueKey('${recipe.title}-$i'),
              direction: DismissDirection.startToEnd,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              confirmDismiss: (_) async {
                setState(() => _pendingDeleteIndex = i);
                await Future.delayed(const Duration(milliseconds: 140));
                return true;
              },
              onDismissed: (_) {
                final removed = _recipes.removeAt(i);
                _listKey.currentState!.removeItem(
                  i,
                  (_, anim) => FadeTransition(
                    opacity: CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutCubic,
                    ),
                    child: recipeCard(
                      removed,
                      _normalizeImageUrl(removed.image),
                    ),
                  ),
                  duration: const Duration(milliseconds: 0),
                );
                StorageService().deleteRecipe(removed.title);
                setState(() => _pendingDeleteIndex = null);
                if (_recipes.isEmpty) setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color:
                      isPending
                          ? Colors.red.withOpacity(0.08)
                          : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: recipeCard(recipe, imageUrl),
              ),
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _recipes.isEmpty ? emptyState() : (isTablet ? grid() : list()),
        ),
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
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: widget.url,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
