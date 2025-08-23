// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mestura';

  @override
  String get homePrompt => '¿Qué te apetece?';

  @override
  String get searchButton => 'Buscar receta';

  @override
  String get surpriseButton => 'Sorpréndeme';

  @override
  String get ingredientsTitle => 'Ingredientes';

  @override
  String get stepsTitle => 'Pasos';

  @override
  String get rewriteButton => 'Reescribir sin ingredientes seleccionados';

  @override
  String get savedTitle => 'Recetas Guardadas';

  @override
  String get noSavedRecipes => 'No tienes recetas guardadas aún.';

  @override
  String get filterTips => 'Tips';

  @override
  String get filterIngredients => 'Ingredientes';

  @override
  String get filterDate => 'Fecha';

  @override
  String get saveButton => 'Guardar';

  @override
  String get savedConfirmation => 'Receta guardada!';

  @override
  String get shareButton => 'Compartir';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get preferenceVegan => 'Vegan';

  @override
  String get preferenceGlutenFree => 'Sin gluten';

  @override
  String get language => 'Idioma';

  @override
  String get languageSettingLabel => 'Idioma de la app';

  @override
  String get subscription => 'Cuenta / Suscripción';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get inappropriateInput => 'Tu consulta no es apropiada para una receta. Intenta con otra idea.';

  @override
  String get loadingMessage => 'Cocinando la receta...';
}
