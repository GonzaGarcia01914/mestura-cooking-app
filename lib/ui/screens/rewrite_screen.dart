import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RewriteScreen extends StatelessWidget {
  const RewriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(s.rewriteButton)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen (misma receta, diferente preparación)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/bruschetta.jpg',
                fit: BoxFit.cover,
                height: 180,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              'Bruschetta (modificada)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Ingredientes reescritos
            Text(
              s.ingredientsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const IngredientList(),

            const SizedBox(height: 24),

            // Pasos reescritos
            Text(s.stepsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const StepList(),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: guardar receta
                    },
                    child: Text(s.saveButton),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: compartir receta
                    },
                    child: Text(s.shareButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IngredientList extends StatelessWidget {
  const IngredientList({super.key});

  @override
  Widget build(BuildContext context) {
    final ingredients = ['Tomatoes', 'Olive oil', 'Basil']; // Ejemplo reescrito

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          ingredients
              .map(
                (ingredient) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $ingredient'),
                ),
              )
              .toList(),
    );
  }
}

class StepList extends StatelessWidget {
  const StepList({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Toast sliced tomatoes in the oven at 200°C.',
      'Spread them over bread and drizzle olive oil.',
      'Add fresh basil on top.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        steps.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('${index + 1}. ${steps[index]}'),
        ),
      ),
    );
  }
}
