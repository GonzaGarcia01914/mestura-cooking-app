import 'package:flutter/material.dart';
import 'package:mestura/ui/widgets/glass_alert.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/openai_service.dart';
//import '../../core/navigation/run_with_loading.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/ad_gate.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_title.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_top_bar.dart';
import '../style/app_style.dart';
import 'recipe_screen.dart';
import 'loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final ScrollController _homeScrollCtrl = ScrollController();
  final _openAI = OpenAIService();
  bool _loading = false;
  int _servings = 2;
  int? _maxCalories;
  bool _countMacros = false;

  static const double _threshold = 160.0; // píxeles para ocultar completamente

  String _t(BuildContext ctx, String es, String en) =>
      Localizations.localeOf(ctx).languageCode == 'es' ? es : en;

  Future<void> _showErrorDialog(String rawMessage) async {
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    final title = lang == 'es' ? 'Ups…' : 'Oops…';
    final ok = lang == 'es' ? 'Entendido' : 'OK';
    final message = rawMessage.replaceFirst('Exception: ', '');

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'error',
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
  void dispose() {
    _homeScrollCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() => _loading = true);
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      final isFood = await _openAI.isFood(query);
      if (!isFood) {
        throw Exception(
          languageCode == 'es'
              ? 'Vamos a limitarnos a cosas comestibles.'
              : 'Let’s stick to edible things.',
        );
      }
      if (!mounted) return;
      setState(() => _loading = false);

      await AdGate.registerAction();

      bool loadingShown = false;
      final pushedAt = DateTime.now();
      const minShowMs = 700;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoadingScreen(),
          settings: const RouteSettings(name: 'loading'),
        ),
      );
      loadingShown = true;

      final recipeFuture = _openAI.generateRecipe(
        query,
        language: languageCode,
        generateImage: false,
        servings: _servings,
        includeMacros: _countMacros,
        maxCaloriesKcal: _maxCalories,
      );

      bool adClosed = true;
      Future<bool>? adFuture;
      if (await AdGate.shouldShowThisTime()) {
        adClosed = false;
        adFuture = AdService.instance.showIfAvailable().whenComplete(() {
          adClosed = true;
        });
      }

      final recipe = await recipeFuture;
      if (!mounted) return;

      Future<void> closeLoadingAndGo() async {
        final elapsed = DateTime.now().difference(pushedAt).inMilliseconds;
        if (elapsed < minShowMs) {
          await Future.delayed(Duration(milliseconds: minShowMs - elapsed));
        }
        if (!mounted) return;
        if (loadingShown && Navigator.canPop(context)) {
          Navigator.of(context).pop();
          loadingShown = false;
        }
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)));
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
      setState(() => _loading = false);
      if (ModalRoute.of(context)?.settings.name == 'loading' &&
          Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      await _showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final style = AppStyle.of(context);

    return AppScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(title: Text(s.appTitle), blurSigma: 0, tintOpacity: 0),

      drawer: AppSideDrawer(
        header: Row(
          children: [
            Image.asset('assets/images/logo_sin_fondo.png', height: 52),
            const SizedBox(width: 12),
            Text(
              'Mestura',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        items: [
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text(s.savedTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/saved');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(s.settingsTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        footer: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'v1.0.0',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      ),

      body: SingleChildScrollView(
        controller: _homeScrollCtrl,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: 25,
          vertical: style.padding.vertical * 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),

            // === LOGO: fade por scroll, sin colapsar el layout ===
            Center(
              child: AnimatedBuilder(
                animation: _homeScrollCtrl, // se reconstruye solo el logo
                builder: (_, child) {
                  final has = _homeScrollCtrl.hasClients;
                  final offset = has ? _homeScrollCtrl.offset : 0.0;
                  final max =
                      has ? _homeScrollCtrl.position.maxScrollExtent : 0.0;

                  // umbral efectivo: si hay poco scroll, usa max para que llegue a 0
                  final effective =
                      (max > 0)
                          ? (max < _threshold ? max : _threshold)
                          : _threshold;

                  double t = effective == 0 ? 0.0 : (offset / effective);
                  if (t < 0)
                    t = 0;
                  else if (t > 1)
                    t = 1;

                  // opcional: suaviza la curva
                  final opacity = 1.0 - Curves.easeOutCubic.transform(t);

                  // Mantiene el espacio (no colapsa) y no intercepta toques cuando es 0
                  return IgnorePointer(
                    ignoring: opacity <= 0.01,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: Image.asset(
                  'assets/images/logo_sin_fondo.png',
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            AppTitle(s.homePrompt),
            const SizedBox(height: 16),

            AppTextField(
              controller: _controller,
              hintText: s.homePrompt,
              onSubmitted: (_) => _generateRecipe(),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  title: Text(
                    s.advancedOptions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  // Evita el auto-scroll “raro” al expandir
                  onExpansionChanged: (expanded) {
                    if (expanded && _homeScrollCtrl.hasClients) {
                      final keep = _homeScrollCtrl.offset;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _homeScrollCtrl.hasClients) {
                          _homeScrollCtrl.jumpTo(keep);
                        }
                      });
                    }
                  },

                  children: [
                    // --- Invitados ---
                    Row(
                      children: [
                        Text(
                          s.numberOfGuests,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _servings = (_servings - 1);
                              if (_servings < 1) _servings = 1;
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_servings',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _servings = (_servings + 1);
                              if (_servings > 12) _servings = 12;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),

                    // --- Calorías máx. (por ración) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(context, 'Calorías máx.', 'Max calories'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                _t(context, '(por ración)', '(per serving)'),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => setState(() {
                                final v = (_maxCalories ?? 600) - 50;
                                _maxCalories = v < 200 ? 200 : v;
                              }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          _maxCalories == null ? '—' : '${_maxCalories} kcal',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed:
                              () => setState(() {
                                final v = (_maxCalories ?? 600) + 50;
                                _maxCalories = v > 1500 ? 1500 : v;
                              }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // --- Macros ---
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _countMacros,
                      onChanged: (v) => setState(() => _countMacros = v),
                      title: Text(
                        _t(
                          context,
                          'Contar macros (estimados)',
                          'Include macros (estimated)',
                        ),
                      ),
                      subtitle: Text(
                        _t(
                          context,
                          'Añade calorías y macronutrientes por ración.',
                          'Adds calories & macros per serving.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),

                    // --- Botón Restablecer ---
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _servings = 2;
                            _maxCalories = null;
                            _countMacros = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.6,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(_t(context, 'Restablecer', 'Reset')),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            AppPrimaryButton(
              loading: _loading,
              onPressed: _generateRecipe,
              child: Text(s.searchButton, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
