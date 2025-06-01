import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String activeFilter = 'tips'; // Puede ser 'tips', 'ingredients', 'date'

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.savedTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filtros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FilterChip(
                  label: s.filterTips,
                  selected: activeFilter == 'tips',
                  onTap: () => setState(() => activeFilter = 'tips'),
                ),
                _FilterChip(
                  label: s.filterIngredients,
                  selected: activeFilter == 'ingredients',
                  onTap: () => setState(() => activeFilter = 'ingredients'),
                ),
                _FilterChip(
                  label: s.filterDate,
                  selected: activeFilter == 'date',
                  onTap: () => setState(() => activeFilter = 'date'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lista de recetas guardadas
            const Expanded(child: SavedRecipeList()),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }
}

class SavedRecipeList extends StatelessWidget {
  const SavedRecipeList({super.key});

  @override
  Widget build(BuildContext context) {
    final recipes = [
      {'title': 'Fettuchetta', 'image': 'assets/images/fettuchetta.jpg'},
      {'title': 'Fettuccine Alfredo', 'image': 'assets/images/fettuccine.jpg'},
      {'title': 'Caprese Salad', 'image': 'assets/images/caprese.jpg'},
    ];

    return GridView.builder(
      itemCount: recipes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/recipe');
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    recipe['image']!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recipe['title']!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
