import 'dart:ui';

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
  final _openAI = OpenAIService();
  bool _loading = false;
  int _servings = 2;

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
      barrierColor: Colors.black.withOpacity(0.35), // velo suave
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

  Future<void> _generateRecipe() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() => _loading = true); // spinner SOLO durante isFood
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      // 1) Filtro rápido: ¿es comida?
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

      // 2) Contador global de usos (Home + Rewrite)
      await AdGate.registerAction();

      // 3) Mostramos Loading primero (el anuncio irá por encima)
      bool loadingShown = false;
      final pushedAt = DateTime.now();
      const minShowMs = 700; // anti-flicker
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoadingScreen(),
          settings: const RouteSettings(name: 'loading'),
        ),
      );
      loadingShown = true;

      // 4) Lanzamos la generación YA (en paralelo al anuncio)
      final recipeFuture = _openAI.generateRecipe(
        query,
        language: languageCode,
        generateImage: false,
        servings: _servings,
      );

      // 5) Si toca anuncio, lo mostramos SOBRE la Loading y esperamos a su cierre en paralelo
      bool adClosed = true;
      Future<bool>? adFuture;
      if (await AdGate.shouldShowThisTime()) {
        adClosed = false;
        adFuture = AdService.instance.showIfAvailable().whenComplete(() {
          adClosed = true;
        });
      }

      // 6) Esperamos la receta
      final recipe = await recipeFuture;
      if (!mounted) return;

      // 7) Cerrar loading con mínimo tiempo visible
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RecipeScreen(recipe: recipe)));
      }

      // Si el anuncio sigue abierto, navegamos justo al cerrarse; si no, navegamos ya.
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

      // Si la Loading quedó abierta, ciérrala
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: 25,
          vertical: style.padding.vertical * 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),
            Center(
              child: Image.asset(
                'assets/images/logo_sin_fondo.png',
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            AppTitle(s.homePrompt),
            const SizedBox(height: 24),

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
                    s.advancedOptions, // si tienes l10n cambia por s.advancedOptions
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  children: [
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
