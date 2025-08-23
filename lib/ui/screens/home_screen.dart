import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/openai_service.dart';
import '../../ui/screens/loading_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_title.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_top_bar.dart';
import '../style/app_style.dart';
import 'recipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _openAI = OpenAIService();
  bool _loading = false;

  Future<void> _generateRecipe() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true); // spinner SOLO para isFood

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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoadingScreen()),
      );

      final result = await _openAI.generateRecipe(
        query,
        language: languageCode,
      );

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeScreen(recipe: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        padding: EdgeInsets.symmetric(
          horizontal: 25,
          vertical: style.padding.vertical * 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),

            //Image.asset('assets/images/logo_sin_fondo.png', height: 220),
            Image.asset('assets/images/logo_sin_fondo.png', height: 300),
            //const SizedBox(height: 16),
            AppTitle(s.homePrompt),
            const SizedBox(height: 24),
            AppTextField(
              controller: _controller,
              hintText: s.homePrompt,
              onSubmitted: (_) => _generateRecipe(),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              loading: _loading,
              onPressed: _generateRecipe,
              child: Text(s.searchButton, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed:
                  _loading
                      ? null
                      : () {
                        _controller.text = "Surprise me!";
                        _generateRecipe();
                      },
              child: Text(
                s.surpriseButton,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
