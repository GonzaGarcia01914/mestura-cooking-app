import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mestura/ui/widgets/glass_alert.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers.dart';
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
  static const double _threshold =
      160.0; // pÃƒÂ­xeles para ocultar completamente
  final ValueNotifier<double> _logoOpacity = ValueNotifier<double>(1.0);
  // Ajuste de sensibilidad del fade: mayor = desapariciÃƒÂ³n mÃƒÂ¡s lenta
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

  // Calcula la opacidad segÃƒÂºn el scroll.
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

  Future<void> _openAdvancedOptionsDialog() async {
    final s = AppLocalizations.of(context)!;
    // Copia local para permitir Cancelar sin guardar
    int tmpServings = _servings;
    int? tmpMaxCalories = _maxCalories;
    bool tmpCountMacros = _countMacros;
    int? tmpTime = _timeLimitMinutes;
    String? tmpSkill = _skillLevel;

    // Snapshot original para saber si hay cambios
    final int origServings = _servings;
    final int? origMaxCalories = _maxCalories;
    final bool origCountMacros = _countMacros;
    final int? origTime = _timeLimitMinutes;
    final String? origSkill = _skillLevel;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sbSet) {
            return AlertDialog(
              title: Text(s.advancedOptions),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Invitados
                    Row(
                      children: [
                        Text(
                          s.numberOfGuests,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            sbSet(() {
                              tmpServings = (tmpServings - 1);
                              if (tmpServings < 1) tmpServings = 1;
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$tmpServings',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () {
                            sbSet(() {
                              tmpServings = (tmpServings + 1);
                              if (tmpServings > 12) tmpServings = 12;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // CalorÃ­as mÃ¡x. (por raciÃ³n)
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
                              () => sbSet(() {
                                final v = (tmpMaxCalories ?? 600) - 50;
                                tmpMaxCalories = v < 200 ? 200 : v;
                              }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          tmpMaxCalories == null
                              ? '-'
                              : '${tmpMaxCalories} kcal',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed:
                              () => sbSet(() {
                                final v = (tmpMaxCalories ?? 600) + 50;
                                tmpMaxCalories = v > 1500 ? 1500 : v;
                              }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Macros
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: tmpCountMacros,
                      onChanged: (v) => sbSet(() => tmpCountMacros = v),
                      title: Text(s.includeMacros),
                      subtitle: Text(
                        s.includeMacrosSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),

                    // Tiempo disponible (expandible)
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          title: Text(
                            s.timeAvailable,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _TimeChip(
                                  label: s.timeUnder15,
                                  selected: tmpTime == 15,
                                  onTap: () => sbSet(() => tmpTime = 15),
                                ),
                                _TimeChip(
                                  label: s.time30,
                                  selected: tmpTime == 30,
                                  onTap: () => sbSet(() => tmpTime = 30),
                                ),
                                _TimeChip(
                                  label: s.time60,
                                  selected: tmpTime == 60,
                                  onTap: () => sbSet(() => tmpTime = 60),
                                ),
                                _TimeChip(
                                  label: s.time120,
                                  selected: tmpTime == 120,
                                  onTap: () => sbSet(() => tmpTime = 120),
                                ),
                                _TimeChip(
                                  label: s.timeNoLimit,
                                  selected: tmpTime == null,
                                  onTap: () => sbSet(() => tmpTime = null),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nivel de habilidad (expandible)
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          title: Text(
                            s.skillLevel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _SkillChip(
                                  label: s.skillBasic,
                                  selected: tmpSkill == 'basic',
                                  onTap: () => sbSet(() => tmpSkill = 'basic'),
                                ),
                                _SkillChip(
                                  label: s.skillStandard,
                                  selected: tmpSkill == 'standard',
                                  onTap:
                                      () => sbSet(() => tmpSkill = 'standard'),
                                ),
                                _SkillChip(
                                  label: s.skillElevated,
                                  selected: tmpSkill == 'elevated',
                                  onTap:
                                      () => sbSet(() => tmpSkill = 'elevated'),
                                ),
                                _SkillChip(
                                  label: s.skillAny,
                                  selected: tmpSkill == null,
                                  onTap: () => sbSet(() => tmpSkill = null),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reset full-width button (only when there are changes)
                    const SizedBox(height: 12),
                    Builder(
                      builder: (_) {
                        final hasChanges =
                            !(tmpServings == origServings &&
                                tmpMaxCalories == origMaxCalories &&
                                tmpCountMacros == origCountMacros &&
                                tmpTime == origTime &&
                                tmpSkill == origSkill);
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder:
                              (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SizeTransition(
                                  sizeFactor: anim,
                                  axisAlignment: -1.0,
                                  child: child,
                                ),
                              ),
                          child:
                              hasChanges
                                  ? SizedBox(
                                    key: const ValueKey('reset-visible'),
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        sbSet(() {
                                          tmpServings = 2;
                                          tmpMaxCalories = null;
                                          tmpCountMacros = false;
                                          tmpTime = null;
                                          tmpSkill = null;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        side: BorderSide(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          width: 1.6,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                      child: Text(s.reset),
                                    ),
                                  )
                                  : const SizedBox(
                                    key: ValueKey('reset-hidden'),
                                    height: 0,
                                  ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _servings = tmpServings;
                      _maxCalories = tmpMaxCalories;
                      _countMacros = tmpCountMacros;
                      _timeLimitMinutes = tmpTime;
                      _skillLevel = tmpSkill;
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
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
              // Advanced options in dialog
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openAdvancedOptionsDialog,
                  icon: const Icon(Icons.tune),
                  label: Text(s.advancedOptions),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Restringe los rebuilds del
              // botÃƒÂ³n a los cambios de loading ÃƒÂºnicamente
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
