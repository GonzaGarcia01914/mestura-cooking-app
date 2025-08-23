import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/openai_service.dart';
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
      if (!mounted) return;

      final message =
          e.toString().contains('Prompt rejected')
              ? (languageCode == 'es'
                  ? 'Este contenido no está permitido.'
                  : 'This content is not allowed.')
              : 'Error: ${e.toString()}';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final orangeLight = colorScheme.primary;
    final orangeDark = colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(title: Text(s.appTitle)),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset('assets/images/logo_sin_fondo.png', height: 52),
                  const SizedBox(width: 14),
                  const Text(
                    'Mestura',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            ListTile(
              leading: Icon(Icons.bookmark, color: orangeLight),
              title: Text(s.savedTitle, style: const TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/saved');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: orangeLight),
              title: Text(
                s.settingsTitle,
                style: const TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_sin_fondo.png', height: 260),
            const SizedBox(height: 12),
            Text(
              s.homePrompt,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: s.homePrompt,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: orangeDark, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _generateRecipe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return orangeDark;
                    }
                    return orangeLight;
                  }),
                ),
                child:
                    _loading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          s.searchButton,
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
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
