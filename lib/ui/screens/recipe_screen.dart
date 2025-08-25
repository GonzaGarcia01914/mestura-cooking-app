import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/recipe.dart';
import '../../core/services/openai_service.dart';
import '../../core/services/ad_gate.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/storage_service.dart';
//import '../../core/navigation/run_with_loading.dart';
import 'loading_screen.dart';
// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/glass_alert.dart';
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
  String? _headerImageUrl;
  bool _showHeaderImage = false;
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

  Future<void> _checkIfAlreadySaved() async {
    final storage = StorageService();
    final list = await storage.getSavedRecipes();
    if (!mounted) return;

    String _sig(RecipeModel r) =>
        '${r.title}::${r.ingredients.join('|')}::${r.steps.join('|')}';

    final already = list.any((r) => _sig(r) == _sig(widget.recipe));
    setState(() => _isSaved = already);
  }

  @override
  void didUpdateWidget(covariant RecipeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.image != widget.recipe.image) {
      _prepareHeaderImage();
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

  Future<void> _prepareHeaderImage() async {
    final url = _normalizeImageUrl(widget.recipe.image);
    if (url == null) {
      setState(() {
        _headerImageUrl = null;
        _showHeaderImage = false;
      });
      return;
    }

    // Precargamos: si va bien, recién entonces mostramos el bloque
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

  Future<void> _rewriteRecipe() async {
    final excluded = <String>[];
    for (var i = 0; i < _checked.length; i++) {
      if (!_checked[i]) excluded.add(widget.recipe.ingredients[i]);
    }

    try {
      final openai = OpenAIService();
      final langCode =
          _locale?.languageCode ?? Localizations.localeOf(context).languageCode;

      // 1) Cuenta este uso también
      await AdGate.registerAction();

      // 2) Loading debajo del anuncio
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

      // 3) Generación en paralelo
      final recipeFuture = openai.generateRecipe(
        widget.recipe.title,
        restrictions: excluded,
        language: langCode,
        generateImage: false, // tu flag
      );

      // 4) ¿Toca anuncio? Muéstralo encima de la Loading
      bool adClosed = true;
      Future<bool>? adFuture;
      if (await AdGate.shouldShowThisTime()) {
        adClosed = false;
        adFuture = AdService.instance.showIfAvailable().whenComplete(() {
          adClosed = true;
        });
      }

      // 5) Espera la nueva receta
      final newRecipe = await recipeFuture;
      if (!mounted) return;

      // 6) Cerrar loading (con tiempo mínimo) y navegar
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

        // Reemplaza la receta actual por la reescrita
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RecipeScreen(recipe: newRecipe)),
        );
      }

      // Si el anuncio sigue abierto, navegamos al cerrarse; si no, ya mismo
      if (!adClosed && adFuture != null) {
        adFuture.whenComplete(() {
          if (mounted) closeLoadingAndGo();
        });
      } else {
        await closeLoadingAndGo();
      }
    } catch (e) {
      if (!mounted) return;

      // Si por lo que sea la loading quedó abierta, la cerramos
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
    setState(() => _isSaved = true); // 👈 oculta el botón

    // 👇 Alert “bonito” en lugar de SnackBar
    final lang = Localizations.localeOf(context).languageCode;
    final title = lang == 'es' ? '¡Listo!' : 'Done!';
    final ok = lang == 'es' ? 'Entendido' : 'OK';
    final message = AppLocalizations.of(context)!.savedConfirmation;

    // ignore: use_build_context_synchronously
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'saved',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return Opacity(
          opacity:
              CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ).value,
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

            // Imagen opcional
            if (_showHeaderImage && _headerImageUrl != null) ...[
              FrostedContainer(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _headerImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        if (_showHeaderImage) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted)
                              setState(() => _showHeaderImage = false);
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
