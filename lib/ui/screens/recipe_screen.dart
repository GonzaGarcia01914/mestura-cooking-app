import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/recipe.dart';
import '../../core/providers.dart';
import '../../core/services/ad_gate.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/storage_service.dart';
import 'loading_screen.dart';

// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/glass_alert.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_primary_button.dart';
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

  // Header image (solo aparece si realmente carga)
  String? _headerImageUrl;
  bool _showHeaderImage = false;

  // Guardado
  bool _isSaved = false;

  // AppBar tint con scroll
  final _scrollCtrl = ScrollController();
  double _appBarTint = 0.0; // 0 = transparente, 0.08 = máximo

  @override
  void initState() {
    super.initState();
    _checked = List.generate(widget.recipe.ingredients.length, (_) => true);
    _loadPreferences();
    _checkIfAlreadySaved();
    _prepareHeaderImage();

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

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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
    if (l == 'null' || l == 'none' || l == 'n/a' || l == 'na' || l == '-')
      return null;
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
    final excluded = <String>[];
    for (var i = 0; i < _checked.length; i++) {
      if (!_checked[i]) excluded.add(widget.recipe.ingredients[i]);
    }

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
      if (await AdGate.shouldShowThisTime()) {
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
    final ingredients = widget.recipe.ingredients;
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

            // Ingredientes
            FrostedContainer(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      s.nutritionPerServing,
                    ),
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

            AppPrimaryButton(
              loading: _loading,
              onPressed: _rewriteRecipe,
              child: Text(s.rewriteButton),
            ),
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
