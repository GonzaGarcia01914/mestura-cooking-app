import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/recipe.dart';
import '../../core/providers.dart';
import '../../core/services/ad_gate.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/shopping_list_service.dart';
import '../../models/shopping_item.dart';
import 'loading_screen.dart';
import 'cooking_screen.dart';

// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/glass_alert.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_primary_button.dart';
import '../responsive.dart';
import '../widgets/frosted_container.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  final RecipeModel recipe;

  const RecipeScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  late List<bool> _checked;
  final bool _loading = false;
  Locale? _locale;

  // Ingredientes visibles y eliminados (para reescritura)
  late List<String> _visibleIngredients;
  final List<String> _removedIngredients = <String>[];

  // Header image (solo aparece si realmente carga)
  String? _headerImageUrl;
  bool _showHeaderImage = false;

  // Guardado
  bool _isSaved = false;

  // Shopping list (para añadir ingredientes en tiempo real)
  final _shoppingService = ShoppingListService();
  final List<ShoppingItem> _shoppingItems = <ShoppingItem>[];
  final Set<String> _shoppingItemsLC = <String>{};

  // AppBar tint con scroll
  final _scrollCtrl = ScrollController();
  double _appBarTint = 0.0; // 0 = transparente, 0.08 = máximo

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.recipe.ingredients.length, (_) => true);
    _visibleIngredients = List<String>.from(widget.recipe.ingredients);
    _loadPreferences();
    _checkIfAlreadySaved();
    _prepareHeaderImage();

    // Cargar lista de la compra para reflejar estado en iconos
    () async {
      final loaded = await _shoppingService.load();
      if (!mounted) return;
      setState(() {
        _shoppingItems
          ..clear()
          ..addAll(loaded);
        _shoppingItemsLC
          ..clear()
          ..addAll(loaded.map((e) => e.text.trim().toLowerCase()));
      });
    }();

    _scrollCtrl.addListener(() {
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
  void didUpdateWidget(covariant RecipeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.image != widget.recipe.image) {
      _prepareHeaderImage();
    }
  }

  // Normaliza un texto de ingrediente a su nombre base (p.ej. "300 g de ajo" -> "Ajo")
  String _normalizeIngredient(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    // Quitar comentarios entre paréntesis
    s = s.replaceAll(RegExp(r"\([^\)]*\)"), '');

    // Convertir múltiples espacios a 1
    s = s.replaceAll(RegExp(r"\s+"), ' ');

    // Quitar prefijos de cantidad/unidad comunes (multi-idioma básico)
    final qtyUnit = RegExp(
      r"^(?:(?:\d+[\./,]?\d*|[¼½¾⅓⅔⅛⅜⅝⅞]|una|un|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|a|an|one|two|three|four|five|six|seven|eight|nine|ten)\s*)?" // cantidad
      r"(?:(?:g|gr|gramos?|kg|mg|ml|l|litros?)\b\s*)?" // unidades métricas
      r"(?:(?:cucharaditas?|cucharadas?|cdta|cda|tsp|tbsp|cups?|tazas?|pizcas?|pinch(?:es)?|rodajas?|slices?)\b\s*)?",
      caseSensitive: false,
    );
    s = s.replaceFirst(qtyUnit, '');

    // Si queda una estructura "de/di/of" toma lo que sigue (ej: "cucharada de aceite de oliva")
    final ofMatch = RegExp(r"\b(de|del|de la|de los|de las|di|della|dello|of|do|da|dos|das)\b\s+",
            caseSensitive: false)
        .firstMatch(s);
    if (ofMatch != null) {
      final idx = ofMatch.end;
      s = s.substring(idx);
    }

    // Eliminar modificadores comunes al final (p.ej. "picado", "al gusto", "en polvo")
    s = s.replaceAll(RegExp(
      r"\b(al\s+gusto|a\s+gusto|to\s+taste|en\s+polvo|molido(?:a)?|picad[oa]s?|finamente\s+picad[oa]s?|fresco[s]?|seca?|trocead[oa]s?)\b",
      caseSensitive: false,
    ), '').trim();

    // Limpiar puntuación residual
    s = s.replaceAll(RegExp(r"^[\s,.-]+|[\s,.-]+$"), '');

    // Normalizar espacios
    s = s.replaceAll(RegExp(r"\s+"), ' ').trim();

    if (s.isEmpty) s = raw.trim();

    // Capitalizar primera letra
    if (s.isNotEmpty) {
      s = s[0].toUpperCase() + s.substring(1);
    }
    return s;
  }

  Future<void> _addToShoppingList(String text) async {
    final key = text.trim().toLowerCase();
    if (_shoppingItemsLC.contains(key)) return;
    setState(() {
      _shoppingItems.add(ShoppingItem(text: text));
      _shoppingItemsLC.add(key);
    });
    await _shoppingService.save(_shoppingItems);
  }

  Future<void> _removeFromShoppingList(String text) async {
    final key = text.trim().toLowerCase();
    if (!_shoppingItemsLC.contains(key)) return;
    setState(() {
      final idx = _shoppingItems.indexWhere(
          (e) => e.text.trim().toLowerCase() == key);
      if (idx >= 0) _shoppingItems.removeAt(idx);
      _shoppingItemsLC.remove(key);
    });
    await _shoppingService.save(_shoppingItems);
  }

  void _showAddedSnack(String text) {
    final s = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(s.shoppingAddedItem(text))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _startCookingLabel(AppLocalizations s) {
    try {
      final dynamic d = s;
      final val = d.startCookingButton as String?;
      if (val != null) return val;
    } catch (_) {}
    final code = _locale?.languageCode ?? 'en';
    switch (code) {
      case 'es':
        return 'Empezar a cocinar';
      case 'pt':
        return 'Começar a cozinhar';
      case 'fr':
        return 'Commencer à cuisiner';
      case 'de':
        return 'Mit dem Kochen beginnen';
      case 'it':
        return 'Inizia a cucinare';
      case 'pl':
        return 'Zacznij gotować';
      case 'ru':
        return 'Начать готовить';
      case 'ja':
        return '料理を開始';
      case 'ko':
        return '요리 시작';
      case 'zh':
        return '开始烹饪';
      default:
        return 'Start cooking';
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    if (!mounted) return;
    setState(() => _locale = Locale(languageCode));
  }

  Future<void> _checkIfAlreadySaved() async {
    final storage = StorageService();
    final list = await storage.getSavedRecipes();
    if (!mounted) return;

    String sig(RecipeModel r) =>
        '${r.title}::${r.ingredients.join('|')}::${r.steps.join('|')}';

    final already = list.any((r) => sig(r) == sig(widget.recipe));
    setState(() => _isSaved = already);
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

  Future<void> _prepareHeaderImage() async {
    final url = _normalizeImageUrl(widget.recipe.image);
    if (url == null) {
      setState(() {
        _headerImageUrl = null;
        _showHeaderImage = false;
      });
      return;
    }

    // Precarga: solo mostramos si se resuelve correctamente
    final img = NetworkImage(url);
    final stream = img.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _headerImageUrl = url;
          _showHeaderImage = true;
        });
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!mounted) return;
        setState(() {
          _headerImageUrl = null;
          _showHeaderImage = false;
        });
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  Future<void> _rewriteRecipe() async {
    // Excluir los ingredientes que el usuario ha eliminado
    final excluded = List<String>.from(_removedIngredients);

    try {
      final openai = ref.read(openAIServiceProvider);
      final langCode =
          _locale?.languageCode ?? Localizations.localeOf(context).languageCode;

      // Cuenta uso para publicidad
      await AdGate.registerAction();

      // Loading debajo del anuncio
      bool loadingShown = false;
      final pushedAt = DateTime.now();
      const minShowMs = 700; // anti-flicker
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoadingScreen(),
          settings: const RouteSettings(name: 'loading'),
        ),
      );
      loadingShown = true;

      final recipeFuture = openai.generateRecipe(
        widget.recipe.title,
        restrictions: excluded,
        language: langCode,
        generateImage: false,
        includeMacros: widget.recipe.nutrition != null,
      );

      // Generación en paralelo

      // ¿Anuncio?
      bool adClosed = true;
      Future<bool>? adFuture;
      if (!kIsWeb && await AdGate.shouldShowThisTime()) {
        adClosed = false;
        adFuture = AdService.instance.showIfAvailable().whenComplete(() {
          adClosed = true;
        });
      }

      // Espera receta
      final newRecipe = await recipeFuture;
      if (!mounted) return;

      // Cerrar loading con tiempo mínimo y navegar
      Future<void> closeLoadingAndGo() async {
        final elapsed = DateTime.now().difference(pushedAt).inMilliseconds;
        if (elapsed < minShowMs) {
          await Future.delayed(Duration(milliseconds: minShowMs - elapsed));
        }
        if (!mounted) return;

        if (loadingShown && Navigator.canPop(context)) {
          Navigator.of(context).pop(); // cierra Loading
          loadingShown = false;
        }
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RecipeScreen(recipe: newRecipe)),
        );
      }

      if (!adClosed && adFuture != null) {
        adFuture.whenComplete(() {
          if (mounted) closeLoadingAndGo();
        });
      } else {
        await closeLoadingAndGo();
      }
    } catch (e) {
      if (!mounted) return;

      // Si la loading quedó abierta, ciérrala
      final route = ModalRoute.of(context);
      if (route?.settings.name == 'loading' && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _saveRecipe() async {
    if (_isSaved) return;

    final storage = StorageService();
    await storage.saveRecipe(widget.recipe);
    if (!mounted) return;

    setState(() => _isSaved = true); // oculta el botón

    // Alert bonito
    final s = AppLocalizations.of(context)!;
    final title = s.dialogDoneTitle;
    final ok = s.dialogOk;
    final message = s.savedConfirmation;

    // ignore: use_build_context_synchronously
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'saved',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Opacity(
          opacity: curved.value,
          child: Center(
            child: GlassAlert(
              icon: Icons.check_circle_outline_rounded,
              iconColor: Colors.green,
              accentColor: Colors.green,
              title: title,
              message: message,
              okLabel: ok,
              onOk: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }

  // String _t(String es, String en) =>
  //     (_locale?.languageCode ?? Localizations.localeOf(context).languageCode) ==
  //             'es'
  //         ? es
  //         : en;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ingredients = _visibleIngredients;
    final steps = widget.recipe.steps;

    return AppScaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar(
        title: Text(s.appTitle),
        leading: const BackButton(),
        blurSigma: _appBarTint > 0 ? 6 : 0,
        tintOpacity: _appBarTint,
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.hPadding(context),
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 72 + 8),

                // Imagen opcional (solo cuando ya está lista)
                if (_showHeaderImage && _headerImageUrl != null) ...[
                  FrostedContainer(
                    padding: EdgeInsets.zero,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: _headerImageUrl!,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          errorWidget: (_, __, ___) {
                            if (_showHeaderImage) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() => _showHeaderImage = false);
                                }
                              });
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  widget.recipe.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 20),

                // Ingredientes y Pasos: en tablets/desktop, dos columnas.
                Builder(
                  builder: (context) {
                    final isWide =
                        MediaQuery.of(context).size.width >=
                        Responsive.tabletBreakpoint;
                    final ingredientsWidget = FrostedContainer(
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          title: Text(
                            s.ingredientsTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            ...List.generate(
                              ingredients.length,
                              (i) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      ingredients[i],
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Builder(builder: (context) {
                                        final norm = _normalizeIngredient(
                                          ingredients[i],
                                        );
                                        final isAdded = _shoppingItemsLC
                                            .contains(norm.toLowerCase());
                                        return IconButton(
                                          tooltip: s.shoppingAddTooltip,
                                          onPressed: () async {
                                            if (isAdded) {
                                              await _removeFromShoppingList(
                                                  norm);
                                            } else {
                                              await _addToShoppingList(norm);
                                              if (mounted) _showAddedSnack(norm);
                                            }
                                          },
                                          icon: Icon(
                                            Icons.add_shopping_cart,
                                            color: isAdded
                                                ? Colors.green
                                                : Theme.of(context)
                                                    .iconTheme
                                                    .color,
                                            size: 18,
                                          ),
                                        );
                                      }),
                                      IconButton(
                                        tooltip: s.shoppingRemoveTooltip,
                                        onPressed: () {
                                          final text = ingredients[i];
                                          setState(() {
                                            _visibleIngredients.removeAt(i);
                                            final l =
                                                text.toLowerCase().trim();
                                            final exists =
                                                _removedIngredients.any(
                                              (e) =>
                                                  e.toLowerCase().trim() == l,
                                            );
                                            if (!exists)
                                              _removedIngredients.add(text);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),
                                  if (i < ingredients.length - 1)
                                    Divider(
                                      height: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withOpacity(0.25),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final stepsWidget = FrostedContainer(
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
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
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ingredientsWidget,
                          const SizedBox(height: 8),
                          AppPrimaryButton(
                            loading: _loading,
                            backgroundColor: Colors.orange,
                            onPressed: _rewriteRecipe,
                            child: Text(s.rewriteButton),
                          ),
                          const SizedBox(height: 16),
                          stepsWidget,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ingredientsWidget),
                            const SizedBox(width: 16),
                            Expanded(child: stepsWidget),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppPrimaryButton(
                          loading: _loading,
                          backgroundColor: Colors.orange,
                          onPressed: _rewriteRecipe,
                          child: Text(s.rewriteButton),
                        ),
                      ],
                    );
                  },
                ),

                // Dentro del Column principal, tras el contenedor de pasos:
                if (widget.recipe.nutrition != null) ...[
                  const SizedBox(height: 16),
                  FrostedContainer(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        title: Text(
                          s.nutritionFactsTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(s.nutritionPerServing),
                        children: [
                          _NutritionRow(
                            label: s.nutritionCalories,
                            value:
                                widget.recipe.nutrition!.caloriesKcal != null
                                    ? '${widget.recipe.nutrition!.caloriesKcal} kcal'
                                    : '—',
                          ),
                          _NutritionRow(
                            label: s.nutritionProtein,
                            value:
                                widget.recipe.nutrition!.proteinG != null
                                    ? '${widget.recipe.nutrition!.proteinG!.toStringAsFixed(1)} g'
                                    : '—',
                          ),
                          _NutritionRow(
                            label: s.nutritionCarbs,
                            value:
                                widget.recipe.nutrition!.carbsG != null
                                    ? '${widget.recipe.nutrition!.carbsG!.toStringAsFixed(1)} g'
                                    : '—',
                          ),
                          _NutritionRow(
                            label: s.nutritionFat,
                            value:
                                widget.recipe.nutrition!.fatG != null
                                    ? '${widget.recipe.nutrition!.fatG!.toStringAsFixed(1)} g'
                                    : '—',
                          ),
                          if (widget.recipe.nutrition!.fiberG != null)
                            _NutritionRow(
                              label: s.nutritionFiber,
                              value:
                                  '${widget.recipe.nutrition!.fiberG!.toStringAsFixed(1)} g',
                            ),
                          if (widget.recipe.nutrition!.sugarG != null)
                            _NutritionRow(
                              label: s.nutritionSugar,
                              value:
                                  '${widget.recipe.nutrition!.sugarG!.toStringAsFixed(1)} g',
                            ),
                          if (widget.recipe.nutrition!.sodiumMg != null)
                            _NutritionRow(
                              label: s.nutritionSodium,
                              value:
                                  '${widget.recipe.nutrition!.sodiumMg!.toStringAsFixed(0)} mg',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Nuevo: botón para modo cocina paso a paso (verde destacado)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CookingScreen(recipe: widget.recipe),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_startCookingLabel(s)),
                  ),
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 10),

                if (!_isSaved)
                  OutlinedButton.icon(
                    onPressed: _saveRecipe,
                    icon: const Icon(Icons.bookmark_add),
                    label: Text(s.saveButton),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  const _NutritionRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.textTheme.bodyMedium)),
          Text(
            value,
            style: t.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
