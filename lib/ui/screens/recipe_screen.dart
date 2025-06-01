import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
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
              'Bruschetta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Ingredientes
            Text(
              s.ingredientsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const IngredientChecklist(),

            const SizedBox(height: 24),

            // Pasos
            Text(s.stepsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const StepList(),

            const SizedBox(height: 24),

            // Botón Reescribir
            ElevatedButton(
              onPressed: () {
                // TODO: lógica para reescribir receta
              },
              child: Text(s.rewriteButton),
            ),
          ],
        ),
      ),
    );
  }
}

class IngredientChecklist extends StatelessWidget {
  const IngredientChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final ingredients = ['Baguette', 'Tomatoes', 'Garlic', 'Olive oil'];
    return Column(
      children:
          ingredients
              .map(
                (ingredient) => CheckboxListTile(
                  value: true, // TODO: usar estado real
                  onChanged: (_) {},
                  title: Text(ingredient),
                  contentPadding: EdgeInsets.zero,
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
      'Preheat the oven to 400T (200°C).',
      'Slice the baguette and toast the dices in the oven until golden brown.',
      'Rub garlic on toasted bread, basil on top.',
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
