// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mestura';

  @override
  String get homePrompt => 'What would you like?';

  @override
  String get searchButton => 'Search recipe';

  @override
  String get surpriseButton => 'Surprise me';

  @override
  String get ingredientsTitle => 'Ingredients';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get rewriteButton => 'Rewrite without selected ingredients';

  @override
  String get savedTitle => 'Saved Recipes';

  @override
  String get noSavedRecipes => 'You haven\'t saved any recipes yet.';

  @override
  String get filterTips => 'Tips';

  @override
  String get filterIngredients => 'Ingredients';

  @override
  String get filterDate => 'Date';

  @override
  String get saveButton => 'Save';

  @override
  String get savedConfirmation => 'Recipe saved!';

  @override
  String get shareButton => 'Share';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get preferenceVegan => 'Vegan';

  @override
  String get preferenceGlutenFree => 'Gluten-free';

  @override
  String get language => 'Language';

  @override
  String get languageSettingLabel => 'App language';

  @override
  String get subscription => 'Account / Subscription';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get inappropriateInput => 'Your input is not appropriate for a recipe. Please try a different idea.';
}
