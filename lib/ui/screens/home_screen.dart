import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/services/openai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final query = _controller.text;
    if (query.isEmpty) return;

    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() => _loading = true);
    try {
      final result = await _openAI.generateRecipe(
        query,
        language: languageCode,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeScreen(recipe: result)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.appTitle)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Mestura',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(s.savedTitle),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushNamed(context, '/saved');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(s.settingsTitle),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.homePrompt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: s.homePrompt,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _generateRecipe,
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : Text(s.searchButton),
            ),
            TextButton(
              onPressed: () {
                _controller.text = "Surprise me!";
                _generateRecipe();
              },
              child: Text(s.surpriseButton),
            ),
          ],
        ),
      ),
    );
  }
}
