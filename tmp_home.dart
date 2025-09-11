import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mestura/ui/widgets/glass_alert.dart';
import 'package:mestura/l10n/app_localizations.dart';
import 'package:mestura/core/providers.dart';
//import '../../core/navigation/run_with_loading.dart';

import 'package:mestura/core/services/ad_service.dart';
import 'package:mestura/core/services/ad_gate.dart';
import 'package:mestura/ui/widgets/app_scaffold.dart';
import 'package:mestura/ui/widgets/app_title.dart';
import 'package:mestura/ui/widgets/app_text_field.dart';
import 'package:mestura/ui/widgets/app_drawer.dart';
import 'package:mestura/ui/widgets/app_primary_button.dart';
import 'package:mestura/ui/widgets/app_top_bar.dart';
import 'package:mestura/ui/style/app_style.dart';
import 'package:mestura/ui/screens/recipe_screen.dart';
import 'package:mestura/ui/screens/loading_screen.dart';

final homeLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  final ScrollController _homeScrollCtrl = ScrollController();
  int _servings = 2;
  int? _maxCalories;
  bool _countMacros = false;
  int? _timeLimitMinutes; // nuevo: tiempo disponible (minutos)
  String? _skillLevel; // nuevo: nivel de habilidad: basic|standard|elevated

  // Opacidad del logo controlada por scroll (sin AnimationController)
  static const double _threshold = 160.0; // pÃ­xeles para ocultar completamente
  final ValueNotifier<double> _logoOpacity = ValueNotifier<double>(1.0);
  // Ajuste de sensibilidad del fade: mayor = desapariciÃ³n mÃ¡s lenta
  static const double _fadeThreshold = 220.0;

  Future<void> _showErrorDialog(String rawMessage) async {
    if (!mounted) return;
    final s = AppLocalizations.of(context)!;
    final title = s.dialogErrorTitle;
    final ok = s.dialogOk;
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
  void initState() {
    super.initState();
    _homeScrollCtrl.addListener(_recomputeLogoOpacity);
    // Fija opacidad inicial correcta tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _recomputeLogoOpacity(),
    );
  }

  @override
  void dispose() {
    _homeScrollCtrl.removeListener(_recomputeLogoOpacity);
    _logoOpacity.dispose();
    _homeScrollCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Calcula la opacidad segÃºn el scroll.
  // Usa "umbral efectivo" = min(_threshold, maxScrollExtent) para que SIEMPRE pueda llegar a 0.
  void _recomputeLogoOpacity() {
    if (!_homeScrollCtrl.hasClients) {
      if (_logoOpacity.value != 1.0) _logoOpacity.value = 1.0;
      return;
    }
    final pos = _homeScrollCtrl.position;
    final pixels = pos.pixels;
    final max = pos.maxScrollExtent;

    final double effective =
        (max > 0 && max < _fadeThreshold) ? max : _fadeThreshold;

    double t = effective <= 0 ? 0.0 : (pixels / effective);
    if (max > 0 && max < _fadeThreshold && pixels >= max - 0.5) {
      t = 1.0; // garantiza que llegue a invisible si el scroll es corto
    }
    t = t.clamp(0.0, 1.0);
    final double v = 1.0 - t; // lineal y suave con el scroll

    if ((_logoOpacity.value - v).abs() > 0.001) {
      _logoOpacity.value = v;
    }
  }

  Future<void> _generateRecipe() async {
    final query = _controller.text.trim();
    if (query.isEmpty || ref.read(homeLoadingProvider)) return;

    ref.read(homeLoadingProvider.notifier).state = true;
    final languageCode = Localizations.localeOf(context).languageCode;
    final s = AppLocalizations.of(context)!;
    final openAI = ref.read(openAIServiceProvider);

    try {
      final isFood = await openAI.isFood(query);
      if (!isFood) {
        throw Exception(s.inappropriateInput);
      }
      if (!mounted) return;
      ref.read(homeLoadingProvider.notifier).state = false;

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

      // Set advanced options on the service
      openAI.timeLimitMinutes = _timeLimitMinutes;
      openAI.skillLevel = _skillLevel;

      final recipeFuture = openAI.generateRecipe(
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
      ref.read(homeLoadingProvider.notifier).state = false;
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
            leading: const Icon(Icons.restaurant_menu),
            title: Text(AppLocalizations.of(context)!.preferencesMenu),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/preferences');
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

      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: SingleChildScrollView(
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

              // LOGO con fade por scroll (sin colapso)
              Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: _logoOpacity,
                  builder:
                      (_, op, child) => IgnorePointer(
                        ignoring: op <= 0.01,
                        child: Opacity(opacity: op, child: child),
                      ),
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

                    // Mantiene la posiciÃ³n al expandir / y fuerza mostrar logo al colapsar
                    onExpansionChanged: (expanded) {
                      if (expanded && _homeScrollCtrl.hasClients) {
                        final keep = _homeScrollCtrl.offset;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _homeScrollCtrl.hasClients) {
                            _homeScrollCtrl.jumpTo(keep);
                            _recomputeLogoOpacity();
                          }
                        });
                      } else {
                        // ðŸ”´ Cambio mÃ­nimo: al colapsar, muestra el logo sÃ­ o sÃ­.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _logoOpacity.value = 1.0;
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

                      // --- CalorÃ­as mÃ¡x. (por raciÃ³n) ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.maxCalories,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  s.perServing,
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
                            _maxCalories == null ? 'â€”' : '$_maxCalories kcal',
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
                        title: Text(s.includeMacros),
                        subtitle: Text(
                          s.includeMacrosSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),

                      // --- BotÃ³n Restablecer ---
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _servings = 2;
                              _maxCalories = null;
                              _countMacros = false;
                              _timeLimitMinutes = null;
                              _skillLevel = null;
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
                          child: Text(s.reset),
                        ),
                      ),

                      // --- Tiempo disponible ---
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tiempo disponible',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _TimeChip(
                            label: '< 15 min',
                            selected: _timeLimitMinutes == 15,
                            onTap: () => setState(() => _timeLimitMinutes = 15),
                          ),
                          _TimeChip(
                            label: '30 min',
                            selected: _timeLimitMinutes == 30,
                            onTap: () => setState(() => _timeLimitMinutes = 30),
                          ),
                          _TimeChip(
                            label: '1 h',
                            selected: _timeLimitMinutes == 60,
                            onTap: () => setState(() => _timeLimitMinutes = 60),
                          ),
                          _TimeChip(
                            label: '2 h',
                            selected: _timeLimitMinutes == 120,
                            onTap:
                                () => setState(() => _timeLimitMinutes = 120),
                          ),
                          _TimeChip(
                            label: 'Sin lÃ­mite',
                            selected: _timeLimitMinutes == null,
                            onTap:
                                () => setState(() => _timeLimitMinutes = null),
                          ),
                        ],
                      ),

                      // --- Nivel de habilidad ---
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nivel de habilidad',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _SkillChip(
                            label: 'BÃ¡sico',
                            selected: _skillLevel == 'basic',
                            onTap: () => setState(() => _skillLevel = 'basic'),
                          ),
                          _SkillChip(
                            label: 'EstÃ¡ndar',
                            selected: _skillLevel == 'standard',
                            onTap:
                                () => setState(() => _skillLevel = 'standard'),
                          ),
                          _SkillChip(
                            label: 'Elevado',
                            selected: _skillLevel == 'elevated',
                            onTap:
                                () => setState(() => _skillLevel = 'elevated'),
                          ),
                          _SkillChip(
                            label: 'Cualquiera',
                            selected: _skillLevel == null,
                            onTap: () => setState(() => _skillLevel = null),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Restringe los rebuilds del
              // botÃ³n a los cambios de loading Ãºnicamente
              Consumer(
                builder: (context, ref, _) {
                  final loading = ref.watch(homeLoadingProvider);
                  return AppPrimaryButton(
                    loading: loading,
                    onPressed: _generateRecipe,
                    child: Text(
                      s.searchButton,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SkillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
