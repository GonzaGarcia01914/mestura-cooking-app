import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/preferences_service.dart';
import '../../models/preferences.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/frosted_container.dart';
import '../widgets/glass_alert.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _scrollCtrl = ScrollController();
  double _appBarTint = 0.0;
  final _prefsService = PreferencesService();

  // Local in-memory state
  FoodPreferences _prefs = const FoodPreferences();
  final TextEditingController _dislikedInput = TextEditingController();

  // Options
  static const dietOptions = [
    'vegan',
    'vegetarian',
    'vegetarian_ovo',
    'vegetarian_lacto',
    'vegetarian_strict',
    'pescetarian',
    'flexitarian',
    'mediterranean',
    'lowcarb_keto',
    'lowfat',
    'highprotein',
    'paleo',
    'wholefoods',
    'no_ultra_processed',
    'no_alcohol',
    'spicy_low',
    'spicy_medium',
    'spicy_high',
    'organic',
  ];

  static const medicalOptions = [
    'gluten_free',
    'low_fodmap',
    'low_sodium',
    'low_sugar',
    'low_cholesterol',
    'low_purine',
    'low_oxalate_potassium',
    'lactose_free',
  ];

  static const allergenOptions = [
    'gluten',
    'crustaceans',
    'eggs',
    'fish',
    'peanuts',
    'soy',
    'milk',
    'tree_nuts',
    'celery',
    'mustard',
    'sesame',
    'sulphites',
    'lupin',
    'molluscs',
  ];

  static const religionOptions = [
    'halal',
    'kosher',
    'hindu',
    'jain',
    'buddhist',
    'lent_fasting',
  ];

  String _optionLabel(AppLocalizations s, String key) {
    switch (key) {
      // Diet
      case 'vegan':
        return s.prefVegan;
      case 'vegetarian':
        return s.prefVegetarian;
      case 'vegetarian_ovo':
        return s.prefVegetarianOvo;
      case 'vegetarian_lacto':
        return s.prefVegetarianLacto;
      case 'vegetarian_strict':
        return s.prefVegetarianStrict;
      case 'pescetarian':
        return s.prefPescetarian;
      case 'flexitarian':
        return s.prefFlexitarian;
      case 'mediterranean':
        return s.prefMediterranean;
      case 'lowcarb_keto':
        return s.prefLowCarbKeto;
      case 'lowfat':
        return s.prefLowFat;
      case 'highprotein':
        return s.prefHighProtein;
      case 'paleo':
        return s.prefPaleo;
      case 'wholefoods':
        return s.prefWholeFoods;
      case 'no_ultra_processed':
        return s.prefNoUltraProcessed;
      case 'no_alcohol':
        return s.prefNoAlcohol;
      case 'spicy_low':
        return s.prefSpicyLow;
      case 'spicy_medium':
        return s.prefSpicyMedium;
      case 'spicy_high':
        return s.prefSpicyHigh;
      case 'organic':
        return s.prefOrganic;
      // Medical
      case 'gluten_free':
        return s.prefGlutenFree;
      case 'low_fodmap':
        return s.prefLowFodmap;
      case 'low_sodium':
        return s.prefLowSodium;
      case 'low_sugar':
        return s.prefLowSugar;
      case 'low_cholesterol':
        return s.prefLowCholesterol;
      case 'low_purine':
        return s.prefLowPurine;
      case 'low_oxalate_potassium':
        return s.prefLowOxalatePotassium;
      case 'lactose_free':
        return s.prefLactoseFree;
      // Allergens
      case 'gluten':
        return s.allergenGluten;
      case 'crustaceans':
        return s.allergenCrustaceans;
      case 'eggs':
        return s.allergenEggs;
      case 'fish':
        return s.allergenFish;
      case 'peanuts':
        return s.allergenPeanuts;
      case 'soy':
        return s.allergenSoy;
      case 'milk':
        return s.allergenMilk;
      case 'tree_nuts':
        return s.allergenTreeNuts;
      case 'celery':
        return s.allergenCelery;
      case 'mustard':
        return s.allergenMustard;
      case 'sesame':
        return s.allergenSesame;
      case 'sulphites':
        return s.allergenSulphites;
      case 'lupin':
        return s.allergenLupin;
      case 'molluscs':
        return s.allergenMolluscs;
      // Religion
      case 'halal':
        return s.prefHalal;
      case 'kosher':
        return s.prefKosher;
      case 'hindu':
        return s.prefHindu;
      case 'jain':
        return s.prefJain;
      case 'buddhist':
        return s.prefBuddhist;
      case 'lent_fasting':
        return s.prefLentFasting;
    }
    return key;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      const maxTint = 0.08;
      final off = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
      final t = (off / 48).clamp(0.0, 1.0) * maxTint;
      if ((t - _appBarTint).abs() > 0.004) setState(() => _appBarTint = t);
    });
    _load();
  }

  Future<void> _load() async {
    final p = await _prefsService.load();
    if (!mounted) return;
    setState(() => _prefs = p);
  }

  void _toggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Future<void> _save() async {
    await _prefsService.save(_prefs);
    if (!mounted) return;
    final s = AppLocalizations.of(context)!;
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'prefs-saved',
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
              title: s.dialogDoneTitle,
              icon: Icons.check,
              iconColor: Colors.green,
              accentColor: Colors.greenAccent,
              message: s.preferencesSaved,
              okLabel: s.dialogOk,
              onOk: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _clear() async {
    await _prefsService.clear();
    if (!mounted) return;
    setState(() => _prefs = const FoodPreferences());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _dislikedInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 72 + 8;
    final s = AppLocalizations.of(context)!;

    Widget chipGroup(
      String sectionKey,
      List<String> options,
      List<String> stateList,
    ) {
      String title = s.preferencesSectionDiet;
      if (sectionKey == 'medical')
        title = s.preferencesSectionMedical;
      else if (sectionKey == 'allergens')
        title = s.preferencesSectionAllergens;
      else if (sectionKey == 'intolerances')
        title = s.preferencesSectionIntolerances;
      else if (sectionKey == 'religion')
        title = s.preferencesSectionReligion;

      return FrostedContainer(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            title: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    options.map((k) {
                      final selected = stateList.contains(k);
                      return FilterChip(
                        label: Text(_optionLabel(s, k)),
                        selected: selected,
                        onSelected: (_) => _toggle(stateList, k),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: Text(s.preferencesTitle),
        leading: const BackButton(),
        blurSigma: _appBarTint > 0 ? 6 : 0,
        tintOpacity: _appBarTint,
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.preferencesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            chipGroup('diet', dietOptions, _prefs.diet),
            const SizedBox(height: 12),
            chipGroup('medical', medicalOptions, _prefs.medical),
            const SizedBox(height: 12),
            chipGroup('allergens', allergenOptions, _prefs.allergensAvoid),
            const SizedBox(height: 12),
            chipGroup('religion', religionOptions, _prefs.religion),
            const SizedBox(height: 12),

            FrostedContainer(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.preferencesDisliked,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._prefs.dislikedIngredients.map(
                        (e) => InputChip(
                          label: Text(e),
                          onDeleted: () {
                            setState(
                              () => _prefs.dislikedIngredients.remove(e),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _dislikedInput,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: s.preferencesAddIngredientPlaceholder,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (v) {
                            final t = v.trim();
                            if (t.isEmpty) return;
                            setState(() {
                              _prefs.dislikedIngredients.add(t);
                              _dislikedInput.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: Text(s.preferencesClear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          s.preferencesSave,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
